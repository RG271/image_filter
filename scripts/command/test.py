# Command Zynq PL Firmware over its Debug Serial Port
#
# author: RK
# date:   8/2/2025 - 8/16/2025

import serial
import struct


COMMAND_HEADER  = 0xC0   # command packets' header byte
RESPONSE_HEADER = 0xC1   # response packets' header byte


def main():
    port = 'COM7'
    ser = serial.Serial(port, baudrate = 921600, timeout = 0.5)
    if not ser.is_open:
        print(f'Could not open serial port {port}')
        return
    print(f'Opened serial port {port}')
    try:

        # Send a write packet to turn on LEDs
        m = 0   # module (0 .. 127)
        a = 3   # address in module's address space (0 .. 2**24-1)
        d = 5   # data to write
        cmd = 0<<31 | m<<24 | a
        checksum = (cmd ^ cmd>>8 ^ cmd>>16 ^ cmd>>24 ^
                    d ^ d>>8 ^ d>>16 ^ d>>24) & 0xFF ^ 0xFF
        packet = struct.pack('<BIIB', COMMAND_HEADER, cmd, d, checksum)
        ser.write(packet)
        print('Sent a write command packet')

        # Send a read packet to read back the LED enable bits
        m = 0   # module (0 .. 127)
        a = 3   # address in module's address space (0 .. 2**24-1)
        cmd = 1<<31 | m<<24 | a
        checksum = (cmd ^ cmd>>8 ^ cmd>>16 ^ cmd>>24) & 0xFF ^ 0xFF
        packet = struct.pack('<BIB', COMMAND_HEADER, cmd, checksum)
        ser.write(packet)
        print('Sent a read command packet')
        packet = ser.read(6)
        if len(packet) != 6:
            raise Exception(f'Response length should be 6 but was {len(packet)}')
        packet = struct.unpack('<BIB', packet)
        if packet[0] != RESPONSE_HEADER:
            raise Exception('Invalid response header')
        d = packet[1]
        checksum = (d ^ d>>8 ^ d>>16 ^ d>>24) & 0xFF ^ 0xFF
        if packet[2] != checksum:
            raise Exception('Invalid response checksum')
        print(f'Response: 0x{d:08X}')

    except serial.SerialException as e:
        print(f'Serial port error: {e}')

    except Exception as e:
        print(f'Error: {e}')

    finally:
        if ser.is_open:
            ser.close()
            print(f'Closed serial port {port}')


if __name__ == '__main__':
    main()
