#define _CRT_SECURE_NO_WARNINGS
#include <cstdlib>
#include <cstring>
#include <signal.h>
#include <unistd.h>
#include "common.h"
#include "peripherals.h"
#include "app.h"



// **************************
// *  Command-Line Scanner  *
// **************************

static int nArgs = 0;   // number of arguments remaining (>=0)
static char **vArg;     // pointer to array of arguments remaining


// Begin Scanning Command-Line Arguments
// in: argc, argv = the arguments that were passed to main()
static void scan(int argc, char **argv) {
    nArgs = argc>=0 ? argc : 0;  vArg = argv;
    if (nArgs != 0) { nArgs--;  vArg++; }
}


// Skip N Arguments
// in: n = number of arguments to skip (default: 1)
static void skip(int n = 1) {
    if (n < 0)  n = 0;
    if (n > nArgs)  n = nArgs;
    nArgs -= n;  vArg += n;
}


// Chomp Command-Line Switch
// in: sw = switch, e.g. "-e"
static bool chomp(const char *sw) {
    if (nArgs >= 1 && strEq(vArg[0], sw)) { skip();  return true; }
    return false;
}


// Chomp Command-Line Switch with uint32_t Argument
// in: sw = switch, e.g. "-e"
// out: x = value (=0 if not success)
//      returns true if success, else false
static bool chomp(const char *sw, uint32_t &x) {
    if (nArgs >= 2 && strEq(vArg[0], sw) && strToUInt32(vArg[1], x)) { skip(2);  return true; }
    x = 0;
    return false;
}


// Chomp Command-Line Switch with int Argument
// in: sw = switch, e.g. "-e"
// out: x = value (=0 if not success)
//      returns true if success, else false
static bool chomp(const char *sw, int &x) {
    if (nArgs >= 2 && strEq(vArg[0], sw) && strToInt(vArg[1], x)) { skip(2);  return true; }
    x = 0;
    return false;
}


// Chomp Command-Line Switch with int, int Arguments
// in: sw = switch, e.g. "-w"
// out: x = value (=0 if not success)
//      y = value (=0 if not success)
//      returns true if success, else false
static bool chomp(const char *sw, int &x, int &y) {
    if ( nArgs >= 3 &&
         strEq(vArg[0], sw) &&
         strToInt(vArg[1], x) &&
         strToInt(vArg[2], y)
       ) { skip(3);  return true; }
    x = y = 0;
    return false;
}


// Chomp Command-Line Switch with int, int, uint32_t Arguments
// in: sw = switch, e.g. "-w"
// out: x = value (=0 if not success)
//      y = value (=0 if not success)
//      z = value (=0 if not success)
//      returns true if success, else false
static bool chomp(const char *sw, int &x, int &y, uint32_t &z) {
    if ( nArgs >= 4 &&
         strEq(vArg[0], sw) &&
         strToInt(vArg[1], x) &&
         strToInt(vArg[2], y) &&
         strToUInt32(vArg[3], z)
       ) { skip(4);  return true; }
    x = y = 0;  z = 0;
    return false;
}


// Chomp Command-Line Switch with String Argument
// in: sw = switch, e.g. "-e"
// out: p = pointer to string argument (=nullptr if not success)
//      returns true if success, else false
static bool chomp(const char *sw, const char *&p) {
    if (nArgs >= 2 && strEq(vArg[0], sw)) { p = vArg[1];  skip(2);  return true; }
    p = nullptr;
    return false;
}


// Chomp Command-Line Switch with an int and string Argument
// in: sw = switch, e.g. "-e"
// out: x = value (=0 if not success)
//      p = pointer to string argument (=nullptr if not success)
//      returns true if success, else false
static bool chomp(const char *sw, int &x, const char *&p) {
    if (nArgs >= 3 && strEq(vArg[0], sw) && strToInt(vArg[1], x)) { p = vArg[2];  skip(3);  return true; }
    x = 0;  p = nullptr;
    return false;
}


// Chomp Command-Line Switch with Two String Arguments
// in: sw = switch, e.g. "-e"
// out: p1 = pointer to string argument #1 (=nullptr if not success)
//      p2 = pointer to string argument #2 (=nullptr if not success)
//      returns true if success, else false
static bool chomp(const char *sw, const char *&p1, const char *&p2) {
    if (nArgs >= 3 && strEq(vArg[0], sw)) {
        p1 = vArg[1];
        p2 = vArg[2];
        skip(3);
        return true;
    }
    p1 = p2 = nullptr;
    return false;
}


// Chomp Command-Line Filename with Specified Extension
// in: ext = file extension, e.g. ".script" or ".wav"
// out: fn = pointer to filename string (=nullptr if not success)
//      returns true if success, else false
static bool chompFn(const char *ext, const char *&fn) {
    if (nArgs >= 1 && strEndsWith(vArg[0], ext)) { fn = vArg[0];  skip();  return true; }
    fn = nullptr;
    return false;
}



// **********
// *  Main  *
// **********


// Print Help
static void help() {
    const char title[] = APP_TITLE;
    printf( "\n%s  " APP_DATE " (fw %X/%X/20%02X)  " APP_AUTHOR "\n",
            title,
            APP_FW_BUILD >> 16 & 0xFF, APP_FW_BUILD >> 8 & 0xFF, APP_FW_BUILD >> 24 & 0xFF );
    for (int n=strlen(title); --n>=0;  )  putchar('=');
    puts( "\n\n"
        "usage:  sudo ./" APP_FILE " <option>*\n\n"
        "<option>:\n"
//      "  PYNQ-Z2 Commands\n"
//      "    -4 <u>                      -- Set 4-bit enable mask for LEDs {LD3, LD2, LD1, LD0} (0..15)\n"
//      "    -3 <u>                      -- Set 3-bit enable mask for LED LD5 {Red, Green, Blue} (0..7)\n"
        "  Miscellaneous Commands\n"
        "    -h, --help                  -- Print this help\n"
        "    -r <mod> <addr>             -- Read 32-bit word from module <mod>, address <addr>\n"
        "    -w <mod> <addr> <x>         -- Write 32-bit word <x> to module <mod>, address <addr>\n"
        "    -s                          -- Print all peripherals' status\n"
    );
}


// Main
int main(int argc, char *argv[]) {
    if (argc == 1 || (argc == 2 && (strEq(argv[1], "-h") || strEq(argv[1], "--help"))))  { help();  return 0; }
    const char *dev, *fn;
    uint32_t u, z;
    int i, x, y;
    int errCode = 0;
    try {
        peripherals.init();
        scan(argc, argv);
        while (nArgs != 0)
        if (chomp("-h"))  help();
        else if (chomp("-r", x, y)) {
            z = peripherals.dap.read(x, y);
            printf("0x%08X = %u\n", z, z);
        }
        else if (chomp("-w", x, y, z))  peripherals.dap.write(x, y, z);
        else if (chomp("-s")) { putchar('\n');  peripherals.printStatus(); }
//      else if (chomp("-4", u))  peripherals.bio.setLedsLD03(u);
//      else if (chomp("-3", u))  peripherals.bio.setRgbLedLD5(u);
        else  throwException("Command-Line Syntax Error at \"%s\"", *vArg);
    }
    catch (const Exception &e) {
        printf("ERROR at %s:%d : %s\n", e.fileName, e.lineNo, e.what());
        errCode = 1; 
    }
    return errCode;
}
