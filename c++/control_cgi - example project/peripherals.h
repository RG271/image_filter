#ifndef _PERIPHERALS_H
#define _PERIPHERALS_H

#include <cstdint>
#include <sys/mman.h>   // for mmap() and off_t


/* -----  Basic I/O  -----
 *
 * Class for controlling the basic_io peripheral.
 *
 * Peripheral's AXI4-Lite Register Map
 * ===================================
 *
 * Note, Index (below) is a 32-bit register's index; its byte offset from this peripheral's base address is Index * 4.
 *
 * Index   Name           Access   Description
 * -----   ------------   ------   ----------------------------------------------------------------------------------------------------------
 *
 *   0     creationDate     ro     PL firmware's creation date in 32'hYYMMDDHH format (can be used as a globally unique ID for this firmware)
 *
 *   1     buildDate        ro     PL firmware's build date in 32'hYYMMDDHH format
 *
 *   2     usTime           ro     32-bit free-running timer incrementing at 1 MHz (read only) 
 *
 *   3     leds             rw     LEDs' enables (4 bits)
 *                                   Bits   Name           Description
 *                                   -----  -------------  ---------------------------------------------------------------------------
 *                                   31:4   --             unimplemented (always 0)
 *                                   3      LED3           LED  *3 enable (0=off, 1=on)
 *                                   2      LED2           LED  *2 enable (0=off, 1=on)
 *                                   1      LED1           LED  *1 enable (0=off, 1=on)
 *                                   0      LED0           LED  *0 enable (0=off, 1=on)
 *
 *   4     rgbLed            rw    RGB LED LD5's enables (6 bits)
 *                                   Bits   Name           Description
 *                                   -----  -------------  ---------------------------------------------------------------------------
 *                                   31:3   --             unimplemented (always 0)
 *                                   2      LD5red         RGB LED LD5's red   channel (0=off, 1=on)
 *                                   1      LD5green       RGB LED LD5's green channel (0=off, 1=on)
 *                                   0      LD5blue        RGB LED LD5's blue  channel (0=off, 1=on)
 *
 *   5     sw                ro    Switches and Buttons
 *                                   Bits   Name           Description
 *                                   -----  -------------  ---------------------------------------------------------------------------
 *                                   31:6   --             unimplemented (always 0)
 *                                   5      SW1            switch  *1 (0=off, 1=on)
 *                                   4      SW0            switch  *0 (0=off, 1=on)
 *                                   3      BTN3           pushbutton  *3 (0=up, 1=down)
 *                                   2      BTN2           pushbutton  *2 (0=up, 1=down)
 *                                   1      BTN1           pushbutton  *1 (0=up, 1=down)
 *                                   0      BTN0           pushbutton  *0 (0=up, 1=down)
 */
class BasicIO {

private:
    struct IO {
        uint32_t creationDate;
        uint32_t buildDate;
        uint32_t usTime;
        uint32_t leds;
        uint32_t rgbLed;
        uint32_t sw;
    };
    volatile IO *io;
    
public:
    static constexpr off_t ramPhysAddr = 0x43C00000;    // physical memory address of struct IO
    
    BasicIO();
    BasicIO(const BasicIO &) = delete;                  // delete copy constructor
    BasicIO &operator=(const BasicIO &) = delete;       // delete assignment operator
    void init(volatile void *io);
    void deinit();
    uint32_t creationDate() { return io->creationDate; }
    uint32_t buildDate()    { return io->buildDate;    }
    uint32_t usTime()       { return io->usTime;       }
    uint32_t leds()         { return io->leds;         }
    uint32_t rgbLed()       { return io->rgbLed;       }
    uint32_t sw()           { return io->sw;           }
    void setLedsLD03(uint32_t x)  { io->leds   = x; }
    void setRgbLedLD5(uint32_t x) { io->rgbLed = x; }
    void shutdown() { io->leds = io->rgbLed = 0; }      // turn off all LEDs
    void printStatus();
};



/* -----  Beacon Pattern Generator  -----
 *
 * Class for controlling the beacon peripheral.
 *
 * Peripheral's AXI4-Lite Register Map
 * ===================================
 *
 * Note, Index (below) is a 32-bit register's index; its byte offset from this peripheral's base address is Index * 4.
 *
 * Index   Name           Access   Description
 * -----   ------------   ------   ----------------------------------------------------------------------------------------------------------
 *
 *   0     control          rw     Control Register
 *                                   Bits   Name           Description
 *                                   -----  -------------  ---------------------------------------------------------------------------
 *                                   31:8   --             unimplemented (always 0)
 *                                   7      mode           Mode: 1 = SPI, 0 = test mode (output signals sync_spi are forced equal to mask)
 *                                   6:0    mask           Bit mask for test mode
 *
 *   1      dacRightMirror   rw     "Right Mirror" DAC's values
 *                                    Bits   Name           Description
 *                                    -----  -------------  ---------------------------------------------------------------------------
 *                                    31:16  a              WL A (Wavelength A) value
 *                                    15:0   b              WL B (Wavelength B) value
 *
 *   2      dacLeftMirror    rw     "Left Mirror" DAC's values
 *                                    Bits   Name           Description
 *                                    -----  -------------  ---------------------------------------------------------------------------
 *                                    31:16  a              WL A (Wavelength A) value
 *                                    15:0   b              WL B (Wavelength B) value
 *
 *   3      dacPhase         rw     "Phase" DAC's values
 *                                    Bits   Name           Description
 *                                    -----  -------------  ---------------------------------------------------------------------------
 *                                    31:16  a              WL A (Wavelength A) value
 *                                    15:0   b              WL B (Wavelength B) value
 *
 *   4      dacGain          rw     "Gain" DAC's values
 *                                    Bits   Name           Description
 *                                    -----  -------------  ---------------------------------------------------------------------------
 *                                    31:16  a              WL A (Wavelength A) value
 *                                    15:0   b              WL B (Wavelength B) value
 *
 *   5      dacSOA           rw     "SOA" DAC's values
 *                                    Bits   Name           Description
 *                                    -----  -------------  ---------------------------------------------------------------------------
 *                                    31:16  a              WL A (Wavelength A) value
 *                                    15:0   b              WL B (Wavelength B) value
 *
 *   6     sclkPeriod       rw     SPI bus clock's period
 *                                   Bits   Name            Description
 *                                   -----  -------------  ---------------------------------------------------------------------------
 *                                   31:28  --             unimplemented (always 0)
 *                                   27:0   period         SPI bus clock's period, where frequency is 100 MHz / (sclk_period + 1)
 *
 *   7     wlaDuration      rw     Duration of Wavelength A
 *                                   Bits   Name            Description
 *                                   -----  -------------  ---------------------------------------------------------------------------
 *                                   31:20  --             unimplemented (always 0)
 *                                   19:0   duration       Wavelength A is output for duration microseconds (1..1048575; typically >=10)
 *
 *   8     wlbDuration      rw     Duration of Wavelength B
 *                                   Bits   Name            Description
 *                                   -----  -------------  ---------------------------------------------------------------------------
 *                                   31:20  --             unimplemented (always 0)
 *                                   19:0   duration       Wavelength B is output for duration microseconds (1..1048575; typically >=10)
 */
class Beacon {

private:
    static constexpr double CLK_FREQ = 100e6;           // AXI bus' clock frequency in Hz

    struct IO {
        uint32_t control;
        union {
            uint32_t dac[5];
            struct {
                uint32_t dacRightMirror;
                uint32_t dacLeftMirror;
                uint32_t dacPhase;
                uint32_t dacGain;
                uint32_t dacSOA;
            };
        };
        uint32_t sclkPeriod;
        uint32_t wlaDuration;
        uint32_t wlbDuration;
    };
    volatile IO *io;
    
public:
    static constexpr off_t ramPhysAddr = 0x43C10000;    // physical memory address of struct IO
    
    Beacon();
    Beacon(const Beacon &) = delete;                    // delete copy constructor
    Beacon &operator=(const Beacon &) = delete;         // delete assignment operator
    void init(volatile void *io);
    void deinit();
    
    void dac(int i, uint16_t &a, uint16_t &b);
    double sclkFreq() { return CLK_FREQ / (double(io->sclkPeriod) + 1); }
    unsigned wlaDuration() { return io->wlaDuration; }  // get Wavelength A's duration in microseconds (1..1048575)
    unsigned wlbDuration() { return io->wlbDuration; }  // get Wavelength B's duration in microseconds (1..1048575)

    void setModeTest(unsigned x) { io->control = (io->control & ~0xFF) | (x & 0x7F); }   // x = 7-bit mask for controlling output lines
    void setModeNormal() { io->control = (io->control & ~0xFF) | 0x80; }
    void setDac(int i, uint16_t a, uint16_t b);
    void setSclkFreq(double freq);
    void setWlaDuration(unsigned us);
    void setWlbDuration(unsigned us);

    void shutdown() { io->control = 0x20; }             // disable clock, deselect DACs, and set serial output lines to 0
    void printStatus();
};



// -----  Peripherals  -----
// This class is for a singleton object that provides access to all the Zynq peripherals implemented in the PL.
// It maps their physical address spaces into this Linux process' virtual address space.
class Peripherals {

private:
    static constexpr off_t ramPhysAddr = 0x43C00000;  // mmap a block of physical memory from ramPhysAddr to ramPhysAddr+ramSize-1
    static constexpr size_t ramSize    = 0x00080000;  // mmap block's size in bytes
    volatile uint8_t *devMem;                         // pointer to memory mapped region (=0 iff fdDevMem<0)
    static bool progDone();

protected:
    bool initialized;       // true if this object is fully initialized, i.e. if init() was called

public:
    BasicIO bio;
    Beacon beacon;

    Peripherals();
    Peripherals(const Peripherals &) = delete;              // delete copy constructor
    Peripherals &operator=(const Peripherals &) = delete;   // delete assignment operator
    ~Peripherals();
    void init();
    void shutdown();
    void printStatus();
};

extern Peripherals peripherals;


#endif
