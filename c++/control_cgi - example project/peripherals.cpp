#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include "app.h"
#include "common.h"
#include "peripherals.h"


Peripherals peripherals;



// ***************
// *  Basic I/O  *
// ***************


// Constructor
BasicIO::BasicIO() {
    io = nullptr;
}


// Initialize
// in: io = pointer to peripheral's memory region
void BasicIO::init(volatile void *io) {
    this->io = reinterpret_cast<volatile IO *>(io);
}


// Deinitialize
void BasicIO::deinit() {
    io = nullptr;
}


// Print Status (for debugging)
void BasicIO::printStatus() {
    uint32_t x;
    char buf[16];
    puts("Basic I/O");
    printf("    creationDate   =  0x%08X  =  %s  ; 0xYYMMDDHH timestamp\n", io->creationDate, timestampToStr(io->creationDate, buf));
    printf("    buildDate      =  0x%08X  =  %s  ; 0xYYMMDDHH timestamp\n", io->buildDate, timestampToStr(io->buildDate, buf));
    printf("    usTime         =  %10u   ; 1 MHz free-running 32-bit counter\n", io->usTime);
    printf("    leds           =  0x%X          ; LEDs {LD3, LD2, LD1, LD0}\n", io->leds);
    printf("    rgbLed         =  0x%X          ; {Red, Green, Blue} LED LD5\n", io->rgbLed);
    printf("    sw             =  0x%02X         ; Pushbuttons BTN0 through BTN3, and switches SW0 and SW1\n", x = io->sw);
    printf("        bit 5  SW1   =  %u\n", x>>5 & 1);
    printf("        bit 4  SW0   =  %u\n", x>>4 & 1);
    printf("        bit 3  BTN3  =  %u\n", x>>3 & 1);
    printf("        bit 2  BTN2  =  %u\n", x>>2 & 1);
    printf("        bit 1  BTN1  =  %u\n", x>>1 & 1);
    printf("        bit 0  BTN0  =  %u\n", x & 1);
    putchar('\n');
}



// ************
// *  Beacon  *
// ************


// Constructor
Beacon::Beacon() {
    io = nullptr;
}


// Initialize
// in: io = pointer to peripheral's memory region
void Beacon::init(volatile void *io) {
    this->io = reinterpret_cast<volatile IO *>(io);
}


// Deinitialize
void Beacon::deinit() {
    io = nullptr;
}


// Get DAC
// in: i = index (0 = Right Mirror, 1 = Left Mirror, 2 = Phase, 3 = Gain, 4 = SOA)
// out: a = "WL A" (Wavelength A) DAC value (0..0xFFFF, or 0 if index out of range)
//      b = "WL B" (Wavelength A) DAC value (0..0xFFFF, or 0 if index out of range)
void Beacon::dac(int i, uint16_t &a, uint16_t &b) {
    if (i < 0 || i > 4)  throwException("Index Out of Range");
    uint32_t x = io->dac[i];
    a = x >> 16;
    b = x & 0xFFFF;
}


// Set DAC
// in: i = index (0 = Right Mirror, 1 = Left Mirror, 2 = Phase, 3 = Gain, 4 = SOA)
//     a = "WL A" (Wavelength A) DAC value (0..0xFFFF)
//     b = "WL B" (Wavelength A) DAC value (0..0xFFFF)
void Beacon::setDac(int i, uint16_t a, uint16_t b) {
    if (i < 0 || i > 4)  throwException("Index Out of Range");
    io->dac[i] = (uint32_t(a) << 16) | b;
}


// Set SPI Bus Clock Frequency
// in: freq = frequency in Hz
void Beacon::setSclkFreq(double freq) {
    constexpr double MIN_FREQ  =  1.0,
                     MAX_FREQ  =  CLK_FREQ / 4;
    if (freq < MIN_FREQ || freq > MAX_FREQ)  throwException("Frequency Out of Range");
    io->sclkPeriod = uint32_t(CLK_FREQ / freq - 1 + 0.5);
}


// Set Wavelength A's Duration
// in: us = duration in microseconds (MIN_DURATION..MAX_DURATION)
void Beacon::setWlaDuration(unsigned us) {
    constexpr unsigned MIN_DURATION  =  10,         // min. duration is microseconds
                       MAX_DURATION  =  1048575;    // max. duration is microseconds
    if (us < MIN_DURATION || us > MAX_DURATION)  throwException("Wavelength Duration Out of Range");
    io->wlaDuration = us;
}


// Set Wavelength B's Duration
// in: us = duration in microseconds (MIN_DURATION..MAX_DURATION)
void Beacon::setWlbDuration(unsigned us) {
    constexpr unsigned MIN_DURATION  =  10,         // min. duration is microseconds
                       MAX_DURATION  =  1048575;    // max. duration is microseconds
    if (us < MIN_DURATION || us > MAX_DURATION)  throwException("Wavelength Duration Out of Range");
    io->wlbDuration = us;
}


// Print Status (for debugging)
void Beacon::printStatus() {
    uint32_t x;
    char buf[16];
    puts("Beacon Pattern Generator");
    x = io->control;
    printf("    control      =  0x%08X\n", x);
    printf("                      Bit 7     mode  =  %u      0 = TEST mode, 1 = NORMAL mode\n", x >> 7 & 1);
    printf("                      Bits 6:0  mask  =  0x%02X   In TEST mode, output signals are forced to this mask\n", x & 0x7F);
    for (int i = 0; i < 5; i++) {
        x = io->dac[i];
        printf("    dac[%d]       =  0x%08X  =  %4u  %4u\n", i, x, x >> 16, x & 0xFFFF);
    }
    x = io->sclkPeriod;
    printf("    sclkPeriod   =  %-10u  =  %g Hz\n", x, CLK_FREQ / (double(x) + 1));
    printf("    wlaDuration  =  %u us\n", wlaDuration());
    printf("    wlbDuration  =  %u us\n", wlbDuration());
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
    bio.deinit();
    beacon.deinit();
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
        throwException("Failed to open /dev/mem because not root (try sudo). Effective User ID is %d", id);
    }
    devMem = reinterpret_cast<volatile uint8_t *>(mmap(nullptr, ramSize, PROT_READ | PROT_WRITE, MAP_SHARED, fdDevMem, ramPhysAddr));
    close(fdDevMem);
    if (devMem == reinterpret_cast<volatile uint8_t *>(MAP_FAILED)) {
        devMem = nullptr;
        throwException("mmap() Failed");
    }

    bio.init(     devMem + (BasicIO::ramPhysAddr - ramPhysAddr)  );
    beacon.init(  devMem + (Beacon::ramPhysAddr  - ramPhysAddr)  );

    if (bio.creationDate() != APP_FW_CREATION) {
        // try configuring the PL with the correct firmware
        FILE *dst = fopen("/sys/class/fpga_manager/fpga0/firmware", "w");
        if (dst != nullptr) {
            fprintf(dst, "%s\n", APP_FW_BIN);
            fclose(dst);
        }
        // check again if the correct firmware is running in the PL
        if (bio.creationDate() != APP_FW_CREATION)  throwException("Incorrect PL firmware");
    }
    if (bio.buildDate() != APP_FW_BUILD)
        throwException("PL firmware build date is 0x%08X but this utility was built for 0x%08X", bio.buildDate(), APP_FW_BUILD);
}


// Shutdown
// It is not required to call this function.  It places all peripherals in a safe,
// low power, "off" state.  For example, LEDs will be turned off.
void Peripherals::shutdown() {
    bio.shutdown();
    beacon.shutdown();
}


// Print All Peripherals' Status (for debugging)
void Peripherals::printStatus() {
    puts( "AXI4-Lite Peripherals Implemented in Xilinx Zynq 7020's Programmable Logic (PL)\n"
          "-------------------------------------------------------------------------------\n" );
    bio.printStatus();
    beacon.printStatus();
}
