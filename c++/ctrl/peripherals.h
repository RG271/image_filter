#pragma once

#include <cstdint>
#include <sys/mman.h>   // for mmap() and off_t


/* -----  Debug Access Port (DAP)  -----
 *
 * Class for controlling the Debug Access Port (DAP) peripheral.
 *
 * Peripheral's AXI4-Lite Register Map
 * ===================================
 *
 * Note, Index (below) is a 32-bit register's index; its byte offset from this peripheral's base address is Index * 4.
 *
 * Index   Name           Access   Description
 * -----   ------------   ------   ----------------------------------------------------------------------------------------------------------
 *
 *   0     wdata            rw     The 32-bit word that will be written if cmd is a write command
 *
 *   1     rwModAddr        rw     Read/write command
 *                                   Bits   Name           Description
 *                                   -----  -------------  ---------------------------------------------------------------------------
 *                                   31     rw             operation: 0 = write, 1 = read
 *                                   30:24  mod            the module being addressed (0..127)
 *                                   23:0   addr           address (i.e., index) of a 32-bit word in the module's address space
 *
 *   2     rdata            ro     The last 32-bit word read (initially 0)
 *
 *   3     usTime           ro     32-bit free-running timer incrementing at 1 MHz (read only) 
 *
 *   4     creationDate     ro     PL firmware's creation date in 32'hYYMMDDHH format (can be used as a globally unique ID for this firmware)
 *
 *   5     buildDate        ro     PL firmware's build date in 32'hYYMMDDHH format
 *
 */
class Dap {

private:
    struct IO {
        uint32_t wdata;
        uint32_t rwModAddr;
        uint32_t rdata;
        uint32_t usTime;
        uint32_t creationDate;
        uint32_t buildDate;
    };
    volatile IO *io;
    
public:
    static constexpr off_t ramPhysAddr = 0x43C00000;    // physical memory address of struct IO
    
    Dap();
    Dap(const Dap &) = delete;                          // delete copy constructor
    Dap &operator=(const Dap &) = delete;               // delete assignment operator
    void init(volatile void *io);
    void deinit();
    uint32_t wdata()        { return io->wdata;        }
    uint32_t rwModAddr()    { return io->rwModAddr;    }
    uint32_t rdata()        { return io->rdata;        }
    uint32_t usTime()       { return io->usTime;       }
    uint32_t creationDate() { return io->creationDate; }
    uint32_t buildDate()    { return io->buildDate;    }
    uint32_t read(int mod, int addr);
    void write(int mod, int addr, uint32_t data);
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
    Dap dap;

    Peripherals();
    Peripherals(const Peripherals &) = delete;              // delete copy constructor
    Peripherals &operator=(const Peripherals &) = delete;   // delete assignment operator
    ~Peripherals();
    void init();
    void shutdown();
    void printStatus();
};

extern Peripherals peripherals;
