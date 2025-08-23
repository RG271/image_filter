# Command Zynq PL Firmware over its Debug Serial Port
#
# References:
# 1. https://pyserial.readthedocs.io/en/latest/pyserial_api.html
#
# author: RK
# date:   8/2/2025 - 8/23/2025

import numpy as np
import serial
import struct


# Debug Access Port (DAP)
# -----------------------
#
# This class provides a serial link to the FPGA's firmware,
# specifically to the firmware's debug access port.
#
class Dap:

    COMMAND_HEADER  = 0xC0   # command packets' header byte
    RESPONSE_HEADER = 0xC1   # response packets' header byte

    # Intializer
    # in: port = (str) serial port (e.g., 'COM7' on Windows or '/dev/ttyUSB0' on Linux)
    #     baudrate = (int) serial baud rate (e.g., 921600 or 115200)
    #     verbose = (bool) if True, print debugging messages
    def __init__(self, port, baudrate = 921600, verbose = False):
        self.ser = None             # a serial.Serial instance or None
        self.port = port
        self.baudrate = baudrate
        self.verbose = verbose
        # firmware modules
        self.basicio = BasicIO(self)
        self.dcm = DCM(self)

    # Print Status
    def printStatus(self):
        self.basicio.printStatus()
        print()
        self.dcm.printStatus()

    # Enter
    def __enter__(self):
        self.ser = serial.Serial(self.port, baudrate = self.baudrate, timeout = 0.5)
        if self.ser.is_open:
            if self.verbose:
                print(f'INFO: Opened serial port {self.port}, 8N1, {self.baudrate} baud')
        else:
            raise Exception(f'Could not open serial port {self.port}')
        return self

    # Exit
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.ser != None and self.ser.is_open:
            self.ser.close()
            if self.verbose:
                print(f'INFO: Closed serial port {self.port}')
        self.ser = None

    # repr
    def __repr__(self):
        return f'Dap: {self.port} at {self.baudrate} baud'

    # Write a 32-bit word
    # in: mod  = (int 0..127) firmware module's identifier
    #     addr = (int 0..0x00FFFFFF) address in module's address space
    #     data = (int -2**31 .. 2**32-1) 32-bit word
    def write(self, mod, addr, data):
        assert 0 <= mod <= 127, 'Module identifier must be in 0..127'
        assert 0 <= addr <= 0x00FFFFFF, 'Address must be in 0 .. 0x00FFFFFF'
        data &= 0xFFFFFFFF
        # Send write-command packet
        cmd = 0<<31 | mod<<24 | addr
        checksum = ( cmd  ^ cmd>>8  ^ cmd>>16  ^ cmd>>24 ^
                     data ^ data>>8 ^ data>>16 ^ data>>24 ) & 0xFF ^ 0xFF
        packet = struct.pack('<BIIB', self.COMMAND_HEADER, cmd, data, checksum)
        self.ser.write(packet)

    # Read a 32-bit word
    # in: mod  = (int 0..127) firmware module's identifier
    #     addr = (int 0..0x00FFFFFF) address in module's address space
    # out: returns (int 0 .. 2**32-1) 32-bit word
    def read(self, mod, addr):
        assert 0 <= mod <= 127, 'Module identifier must be in 0..127'
        assert 0 <= addr <= 0x00FFFFFF, 'Address must be in 0 .. 0x00FFFFFF'
        # Send read-command packet
        cmd = 1<<31 | mod<<24 | addr
        checksum = (cmd ^ cmd>>8 ^ cmd>>16 ^ cmd>>24) & 0xFF ^ 0xFF
        packet = struct.pack('<BIB', self.COMMAND_HEADER, cmd, checksum)
        self.ser.write(packet)
        # Receive response packet
        packet = self.ser.read(6)
        if len(packet) != 6:
            raise Exception(f'Response packet should be 6 bytes but was {len(packet)}')
        packet = struct.unpack('<BIB', packet)
        if packet[0] != self.RESPONSE_HEADER:
            raise Exception('Corrupt response packet (invalid header byte)')
        data = packet[1]
        checksum = (data ^ data>>8 ^ data>>16 ^ data>>24) & 0xFF ^ 0xFF
        if packet[2] != checksum:
            raise Exception('Corrupt response packet (checksum mismatch)')
        return data

    # Read a Data-Capture-Module Dump
    # out: returns DCM buffer data as an array of 32-bit words (numpy.ndarray of uint32)
    def readDump(self):
        MAX_LEN = 10_000_000   # (int) data array's max. length
        # receive the header word, which is the number of 32-bit data words (0..MAX_LEN)
        data = self.ser.read(4)
        if len(data) != 4:
            raise Exception('Corrupt Debug Capture Module dump (length field is short)')
        n = struct.unpack('<I', data)[0]
        if n > MAX_LEN:
            raise Exception('Corrupt Debug Capture Module dump (invalid length field)')
        # receive and return n data words + 1 checksum word, where n>=0
        b = 4 * (n + 1)     # number of bytes to read (int >0)
        data = self.ser.read(b)
        if len(data) != b:
            raise Exception('Corrupt Debug Capture Module dump (too few bytes received)')
        a = np.array([x[0] for x in struct.iter_unpack('<I', data)], dtype = np.uint32)
        if a.sum(dtype=np.uint32) != 0xFFFFFFFF:
            raise Exception('Corrupt Debug Capture Module dump (invalid checksum)')
        return a[:-1]


# Firmware Module 0: Basic I/O for a PYNQ-Z2 Board
# ------------------------------------------------
#
# This module controls the LEDs and switches on the PYNQ-Z2 board.
#
# Registers:
#
#   0       creationDate     ro     Firmware's creation date in 0xYYMMDDHH format
#
#   1       buildDate        ro     Firmware's build date in 0xYYMMDDHH format
#
#   2       usTime           ro     Current time in microseconds modulo 2**26
#
#   3       leds             rw     LEDs' enables (4 bits)
#                                     Bits   Name           Description
#                                     -----  -------------  ---------------------------------------------------------------------------
#                                     31:4   --             unimplemented (always 0)
#                                     3      LED3           LED #3 enable (0=off, 1=on)
#                                     2      LED2           LED #2 enable (0=off, 1=on)
#                                     1      LED1           LED #1 enable (0=off, 1=on)
#                                     0      LED0           LED #0 enable (0=off, 1=on)
#
#   4       LD4              rw     RGB LED LD4's enables (6 bits)
#                                     Bits   Name           Description
#                                     -----  -------------  ---------------------------------------------------------------------------
#                                     31:3   --             unimplemented (always 0)
#                                     2      LD4red         RGB LED LD4's red   channel (0=off, 1=on)
#                                     1      LD4green       RGB LED LD4's green channel (0=off, 1=on)
#                                     0      LD4blue        RGB LED LD4's blue  channel (0=off, 1=on)
#
#   5       LD5              rw     RGB LED LD5's enables (6 bits)
#                                     Bits   Name           Description
#                                     -----  -------------  ---------------------------------------------------------------------------
#                                     31:3   --             unimplemented (always 0)
#                                     2      LD5red         RGB LED LD5's red   channel (0=off, 1=on)
#                                     1      LD5green       RGB LED LD5's green channel (0=off, 1=on)
#                                     0      LD5blue        RGB LED LD5's blue  channel (0=off, 1=on)
#
#   6       sw               ro     Switches and Buttons
#                                     Bits   Name           Description
#                                     -----  -------------  ---------------------------------------------------------------------------
#                                     31:6   --             unimplemented (always 0)
#                                     5      SW1            switch #1 (0=off, 1=on)
#                                     4      SW0            switch #0 (0=off, 1=on)
#                                     3      BTN3           pushbutton #3 (0=up, 1=down)
#                                     2      BTN2           pushbutton #2 (0=up, 1=down)
#                                     1      BTN1           pushbutton #1 (0=up, 1=down)
#                                     0      BTN0           pushbutton #0 (0=up, 1=down)
#
class BasicIO:

    MODULE = 0   # this firmware module's ID (int: 0..127)

    # Timestamp 0xYYMMDDHH to str
    # in: ts = 32-bit timestamp in the format 0xYYMMDDHH
    # out: returns str
    @staticmethod
    def ts2str(ts):
        return f'20{ts>>24:02X}-{ts>>16 & 0xFF:02X}-{ts>>8 & 0xFF:02X} {ts&0xFF:02X}h'

    # Intializer
    # in: dap = (Dap) debug-access-port object
    def __init__(self, dap):
        self.dap = dap

    # Print Status
    def printStatus(self):
        print(f'Basic I/O (Firmware Module {self.MODULE})')
        x = self.dap.read(self.MODULE, 0)
        print(f'  Creation Date  =  0x{x:08X}  =  {self.ts2str(x)}')
        x = self.dap.read(self.MODULE, 1)
        print(f'  Build Date     =  0x{x:08X}  =  {self.ts2str(x)}')
        x = self.dap.read(self.MODULE, 2)
        print(f'  usTime         =  {x:_} microseconds modulo 2**26')
        x = self.dap.read(self.MODULE, 3)
        print(f'  leds           =  0b{x:04b}')
        x = self.dap.read(self.MODULE, 4)
        print(f'  LD4            =  0b{x:03b} red/green/blue')
        x = self.dap.read(self.MODULE, 5)
        print(f'  LD5            =  0b{x:03b} red/green/blue')
        x = self.dap.read(self.MODULE, 6)
        print(f'  sw             =  0b{x:06b} SW1/SW0/BTN3/BTN2/BTN1/BTN0')


# Firmware Module 1: Debug Capture Module
# ---------------------------------------
#
# This module captures telemetry packets from multiple modules.  It manages a
# 64K x 32b buffer to which the packets are appended.  Each packet should begin with
# a 32-bit word in which bits 31:26 is the packet type (which indicates the packet's
# source and length) and bits 25:0 is a timestamp in microseconds modulo 2**26.
#
# Address:
#   0 .. 24'h00FFFF   data      ro     Buffer, an array of 2**16 uint32_t words
#
#   24'h800000        control   rw     Control register
#
#         Bits  Name   Description
#         ----  -----  -------------------------------------------------------------------------------------
#         31:2   --    Reserved (Always 0)
#         1     dump   Write a 1 to dump the buffer to the Debug Serial Port.  When that 1 is written, the
#                        buffer's length N is latched, N is then transmitted as a 32-bit word (little endian)
#                        followed by the buffer's first N 32-bit words.  Lastly this flag will reset to 0.
#         0     clear  Write a 1 to clear the buffer.  If a telemetry packet is being appended, the
#                        clear operation will happen after the append operation completes.  When done,
#                        this flag will reset to 0.
#
#   24'h800001        length    ro     Number of 32-bit words in the buffer (0 .. 1<<ADDR_WIDTH)
#
#   24'h800002        size      ro     Buffer's capacity in 32-bit words (always 1<<ADDR_WIDTH)
#
#   24'h800003        dec0      rw     Telemetry port 0's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
#
#   24'h800004        dec1      rw     Telemetry port 1's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
#
#   24'h800005        dec2      rw     Telemetry port 2's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
#
#   24'h800006        dec3      rw     Telemetry port 3's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
#
#   24'h800007        dec4      rw     Telemetry port 4's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
#
#   24'h800008        dec5      rw     Telemetry port 5's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
#
class DCM:

    MODULE  = 1           # this firmware module's ID (int: 0..127)
    CONTROL = 0x80_0000   # control register's address

    # Intializer
    # in: dap = (Dap) debug-access-port object
    def __init__(self, dap):
        self.dap = dap

    # Clear
    # Clear the buffer.  If a telemetry packet is being appended, the
    # clear operation will happen after the append operation completes.
    def clear(self):
        self.dap.write(self.MODULE, self.CONTROL, 1 << 0)

    # Set Decimation on a Port
    # in: p = (int: 0..5) telemetry port
    #     d = (int: 0..65535) decimation is N:1 where N is in 1..65535, or 0 to disable the port
    def setDecimation(self, p, d):
        assert 0 <= p <= 5, 'Telemetry port must be in 0..5'
        assert 0 <= d <= 65535, 'Decimation must be in 0..65535'
        self.dap.write(self.MODULE, 0x80_0003 + p, d)

    # Dump to a Binary File
    # Latch the buffer's length N (a 32-bit word), download the buffer's
    # first N 32-bit words, and optionally write them to a binary file.
    # in: saveFn = (str or None) binary file's name to optionally write the data to
    # out: returns the buffer's data as an array of 32-bit words (numpy.ndarray of uint32)
    def dump(self, saveFn = None):
        self.dap.write(self.MODULE, self.CONTROL, 1 << 1)
        data = self.dap.readDump()
        if saveFn != None:
            data.tofile(saveFn)
        return data

    # Print Status
    def printStatus(self):
        print(f'Debug Capture Module (Firmware Module {self.MODULE})')
        x = self.dap.read(self.MODULE, 0x80_0000)
        print(f'  control        =  0x{x:08X}')
        print(f'                    bit 1: dump   =  {x>>1 & 1}')
        print(f'                    bit 0: clear  =  {x & 1}')
        x = self.dap.read(self.MODULE, 0x80_0001)
        print(f'  length         =  {x} 32-bit words')
        x = self.dap.read(self.MODULE, 0x80_0002)
        print(f'  size           =  {x} 32-bit words')
        for i in range(6):
            x = self.dap.read(self.MODULE, 0x80_0003 + i)
            if x == 0:
                desc = f'port {i} is disabled'
            elif x == 1:
                desc = f'port {i} is not decimated'
            else:
                desc = f"port {i}'s decimation is {x}:1"
            print(f'  dec{i}           =  {x}  =  {desc}')
