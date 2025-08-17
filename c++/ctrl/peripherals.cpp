#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include "app.h"
#include "common.h"
#include "peripherals.h"


Peripherals peripherals;



// ***********************
// *  Debug Access Port  *
// ***********************


// Constructor
Dap::Dap() {
    io = nullptr;
}


// Initialize
// in: io = pointer to peripheral's memory region
void Dap::init(volatile void *io) {
    this->io = reinterpret_cast<volatile IO *>(io);
}


// Deinitialize
void Dap::deinit() {
    io = nullptr;
}


// Read a 32-bit word from a module
// in: mod  = module (0 .. 127)
//     addr = address (0 .. 0x00FFFFFF) in the module's address space
// out: returns the 32-bit value read
uint32_t Dap::read(int mod, int addr) {
    if (unsigned(mod) > 127u)  throwException("Module Out of Range 0..127");
    if (unsigned(addr) > 0x00FFFFFFu)  throwException("Address Out of Range 0..0x00FFFFFF");
    io->rwModAddr = (1 << 31) | (mod << 24) | addr;
// !!!TEST  Is extra delay needed here to read the correct value?
    usleep(10);   // !!!TEST
    return io->rdata;
}


// Write a 32-bit word to a module
// in: mod  = module (0 .. 127)
//     addr = address (0 .. 0x00FFFFFF) in the module's address space
//     data = 32-bit value to write
void Dap::write(int mod, int addr, uint32_t data) {
    if (unsigned(mod) > 127u)  throwException("Module Out of Range 0..127");
    if (unsigned(addr) > 0x00FFFFFFu)  throwException("Address Out of Range 0..0x00FFFFFF");
    io->wdata = data;
    io->rwModAddr = (mod << 24) | addr;
}


// Print Status (for debugging)
void Dap::printStatus() {
    char buf[16];
    puts("Debug Access Port");
    printf("    wdata          =  0x%08X   ; 32-bit word to write\n", io->wdata);
    printf("    rwModAddr      =  0x%08X   ; command: rw (bit 31 - 0=write 1=read), module (bits 30:24), address (bits 23:0)\n", io->rwModAddr);
    printf("    rdata          =  0x%08X   ; last 32-bit word read\n", io->rdata);
    printf("    usTime         =  %10u   ; 1 MHz free-running 32-bit counter\n", io->usTime);
    printf("    creationDate   =  0x%08X  =  %s  ; 0xYYMMDDHH timestamp\n", io->creationDate, timestampToStr(io->creationDate, buf));
    printf("    buildDate      =  0x%08X  =  %s  ; 0xYYMMDDHH timestamp\n", io->buildDate, timestampToStr(io->buildDate, buf));
    putchar('\n');
}



// *****************
// *  Peripherals  *
// *****************


// Check if PL is Configured (i.e., Programmed)
// out: returns true if PL configured, else false
bool Peripherals::progDone() {
    FILE *src = fopen("/sys/class/fpga_manager/fpga0/state", "r");
    bool done = false;
    if (src != nullptr) {
        char s[32];
        if (fgets(s, sizeof s, src)!=nullptr && strcmp(s, "operating\n")==0)  done = true;
        fclose(src);
    }
    return done;
}


// Constructor
Peripherals::Peripherals() {
    initialized = false;
    devMem = nullptr;
}


// Destructor
Peripherals::~Peripherals() {
    dap.deinit();
    if (initialized && munmap((void *) devMem, ramSize))  perror("Peripherals::~Peripherals(): munmap() failed");
}


// Initializer
// If not already initialized, initialize this object and if the PL is not already configured with the
// correct firmware, configure it.  This method can be called any number of times.
void Peripherals::init() {
    if (initialized)  return;

    if (!progDone()) throwException("The PL is not configured");
    int fdDevMem = open("/dev/mem", O_RDWR | O_SYNC);
    if (fdDevMem < 0) {
        int id = geteuid();
        if (id == 0)  throwException("Failed to open /dev/mem");
        throwException("Failed to open /dev/mem because not root (try sudo)");
    }
    devMem = reinterpret_cast<volatile uint8_t *>(mmap(nullptr, ramSize, PROT_READ | PROT_WRITE, MAP_SHARED, fdDevMem, ramPhysAddr));
    close(fdDevMem);
    if (devMem == reinterpret_cast<volatile uint8_t *>(MAP_FAILED)) {
        devMem = nullptr;
        throwException("mmap() Failed");
    }

    dap.init( devMem + (Dap::ramPhysAddr - ramPhysAddr) );

    if (dap.creationDate() != APP_FW_CREATION) {
        // try configuring the PL with the correct firmware
        FILE *dst = fopen("/sys/class/fpga_manager/fpga0/firmware", "w");
        if (dst != nullptr) {
            fprintf(dst, "%s\n", APP_FW_BIN);
            fclose(dst);
        }
        // check again if the correct firmware is running in the PL
        if (dap.creationDate() != APP_FW_CREATION)  throwException("Incorrect PL firmware");
    }
    if (dap.buildDate() != APP_FW_BUILD)
        throwException("PL firmware build date is 0x%08X but this utility was built for 0x%08X", dap.buildDate(), APP_FW_BUILD);
}


// Print All Peripherals' Status (for debugging)
void Peripherals::printStatus() {
    puts( "AXI4-Lite Peripherals Implemented in Xilinx Zynq 7020's Programmable Logic (PL)\n"
          "-------------------------------------------------------------------------------\n" );
    dap.printStatus();
}
