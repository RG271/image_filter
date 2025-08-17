#define _CRT_SECURE_NO_WARNINGS
#include <cstdlib>
#include <cstring>
#include <signal.h>
#include <unistd.h>
#include "command.h"
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


// Chomp Command-Line Switch with int, uint16_t, uint16_t Arguments
// in: sw = switch, e.g. "-e"
// out: i = value (=0 if not success)
//      a = value (=0 if not success)
//      b = value (=0 if not success)
//      returns true if success, else false
static bool chomp(const char *sw, int &i, uint16_t &a, uint16_t &b) {
    if ( nArgs >= 4 &&
         strEq(vArg[0], sw) &&
         strToInt(vArg[1], i) &&
         strToUInt16(vArg[2], a) &&
         strToUInt16(vArg[3], b)
       ) { skip(4);  return true; }
    i = 0;  a = b = 0;
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
    printf("\n%s  " APP_DATE " (fw %X/%X/20%02X)  " APP_AUTHOR "\n", title, APP_FW_BUILD >> 16 & 0xFF, APP_FW_BUILD >> 8 & 0xFF, APP_FW_BUILD >> 24 & 0xFF);
    for (int n=strlen(title); --n>=0;  )  putchar('=');
    puts( "\n\n"
        "usage:  " APP_FILE " <option>*\n\n"
        "<option>:\n"
        "  Beacon Pattern Generator\n"
        "    --beacon-signals-test <x>   -- Set test mode, in which the 7 output signals have fixed values <x> (0..0x7F)\n"
        "    --beacon-spi-freq <freq>    -- Set normal (non-test) mode and SPI frequency <freq> Hz (1, 2, 3, ..., 25000000)\n"
        "    --beacon-wl <dac> <a> <b>   -- Set <a> and <b> (0..0xFFFF) values for DAC <dac> (0..4)\n"
        "    --beacon-wla-duration <us>  -- Wavelength A's duration in microseconds (20..1048575)\n"
        "    --beacon-wlb-duration <us>  -- Wavelength B's duration in microseconds (20..1048575)\n"
        "  PYNQ-Z2 Commands\n"
        "    -4 <u>                      -- Set 4-bit enable mask for LEDs {LD3, LD2, LD1, LD0} (0..15)\n"
        "    -3 <u>                      -- Set 3-bit enable mask for LED LD5 {Red, Green, Blue} (0..7)\n"
        "  Miscellaneous Commands\n"
        "    -d                          -- Shutdown all peripherals\n"
        "    -h, --help                  -- Print this help\n"
        "    -s                          -- Print all peripherals' status\n"
        "    -v                          -- Set verbose flag; scripts will print each line executed\n"
    );
}


// Process Command-Line Invocation
// out: returns a system exit code (=0 if success)
static int processCli(int argc, char *argv[]) {

    if (argc == 1 || (argc == 2 && (strEq(argv[1], "-h") || strEq(argv[1], "--help"))))  { help();  return 0; }

    const char *dev, *fn;
    uint32_t u;
    uint16_t a, b;
    int i, x;
    int errCode = 0;
    bool verbose = false;
    try {
        peripherals.init();
        scan(argc, argv);
        while (nArgs != 0)
            if (chomp("-4", u))  peripherals.bio.setLedsLD03(u);
            else if (chomp("-3", u))  peripherals.bio.setRgbLedLD5(u);
            else if (chomp("--beacon-signals-test", u))  peripherals.beacon.setModeTest(u);
            else if (chomp("--beacon-spi-freq", u)) {
                peripherals.beacon.setSclkFreq(u);
                peripherals.beacon.setModeNormal();
            }
            else if (chomp("--beacon-wl", i, a, b))  peripherals.beacon.setDac(i, a, b);
            else if (chomp("--beacon-wla-duration", u))  peripherals.beacon.setWlaDuration(u);
            else if (chomp("--beacon-wlb-duration", u))  peripherals.beacon.setWlbDuration(u);
            else if (chomp("-d"))  peripherals.shutdown();
            else if (chomp("-h"))  help();
            else if (chomp("-s")) { putchar('\n');  peripherals.printStatus(); }
            else if (chomp("-v"))  verbose = true;
            else  throwException("Command-Line Syntax Error at \"%s\"", *vArg);
    }
    catch (const Exception &e) {
        printf("ERROR at %s:%d : %s\n", e.fileName, e.lineNo, e.what());
        errCode = 1; 
    }
    return errCode;
}


// Process CGI Invocation
static void processCgi() {
    CgiRequest cgi;
    try {
        char command[32];       // command name, or "" if none
        peripherals.init();
        cgi.init();
        cgi.get("command", command, sizeof command);
        if (strEq(cgi.requestMethod, "GET")) {
            // Handle HTTP GET
            cmdGetDACsForm(cgi);
        }
        else if (strEq(cgi.requestMethod, "POST")) {
            // Handle HTTP POST
            if (strEq(command, "setDACs"))  cmdSetDACs(cgi);
            else  throwException("Unsupported url-encoded HTTP POST with &quot;command&quot; field of &quot;%s&quot;", command);
        }
        else  throwException("Unsupported HTTP request method &quot;%s&quot;", cgi.requestMethod);
    }
    catch (const Exception &e) {
        // print HTTP Response header
        puts("Status: 400 Bad Request");
        puts("Content-Type: text/html");
        putchar('\n');
        // print HTTP Response body
        printf( "<!DOCTYPE html>\n"
                "<html>\n"
                "<head>\n"
                "  <title>Error</title>\n"
                "</head>\n"
                "<body style=\"color:red; font-family:sans-serif\">\n"
                "  <h1 style=\"font-size:32pt\">Error</h1>\n"
                "  <p style=\"font-size:22pt\">%s</p>\n"
                "  <p style=\"color:gray; font-size:10pt\">source code location:&nbsp; %s:%d</p>\n"
                "</body>\n"
                "</html>\n",
                e.what(), e.fileName, e.lineNo );
    }
}


// Main
int main(int argc, char *argv[]) {
    if (argc == 1) { processCgi();  return 0; }
    else  processCli(argc, argv);
}
