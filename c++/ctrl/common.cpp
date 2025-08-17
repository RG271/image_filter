#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <signal.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
#include "peripherals.h"
#include "common.h"

// Common Functions and Classes
//
// author: Dr. Richard D. Kaminsky
// date:   1/5/2021 - 1/5/2023

Logger logger;



// *****************************************
// *  Keyboard Interrupt (Ctrl-C) Handler  *
// *****************************************

volatile bool ctrlC = false;

static void intHandler(int dummy) { ctrlC = true; }



// ***************
// *  Functions  *
// ***************


// Clamp int into a Range
// in: x = value
//     lo, hi = minimum and maximum limits
// out: returns x saturated into the range lo..hi
int clamp(int x, int lo, int hi) {
    return  x <= lo  ?  lo  :  x >= hi  ?  hi  :  x;
}


// Clamp unsigned into a Range
// in: x = value
//     lo, hi = minimum and maximum limits
// out: returns x saturated into the range lo..hi
unsigned clamp(unsigned x, unsigned lo, unsigned hi) {
    return  x <= lo  ?  lo  :  x >= hi  ?  hi  :  x;
}


// Clamp double into a Range
// in: x = value
//     lo, hi = minimum and maximum limits
// out: returns x saturated into the range lo..hi
double clamp(double x, double lo, double hi) {
    return  x <= lo  ?  lo  :  x >= hi  ?  hi  :  x;
}


// Get Environment Variable
// in: name = environment variable's name
// out: *success = true if variable exists, else false; set to nullptr if not desired
//      returns variable's value or "" if it does not exist
const char *getEnv(const char *name, bool *success) {
    const char *s = getenv(name);
    bool exists = s != nullptr;
    if (success)  *success = exists;
    return  exists ? s : "";
}


// Get Date and Time as a String
// in: bufSz = buffer's size in bytes (>=1)
// out: buf = date/time as a NUL-terminated string
//      returns buf
char *getDateTime(char *buf, size_t bufSz) {
    time_t t;      // time as the number of seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC)
    struct tm c;   // t as local calendar time
    time(&t);
    localtime_r(&t, &c);
    strftime(buf, bufSz, "%Y-%m-%d %H:%M:%S", &c);
    return buf;
}


// Copy String and Truncate, If Necessary
// in: bufSz = output buffer's size in bytes (>=1)
//     s = NUL-terminated string
// out: buf = copy of s, truncated if necessary; so, string will always end with a NUL
//      returns true if not truncated, false if truncated
bool strCpy(char *buf, size_t bufSz, const char *s) {
    size_t n = strlen(s) + 1;
    if (bufSz < n) { memcpy(buf, s, bufSz - 1);  buf[bufSz - 1] = 0;  return false; }
    memcpy(buf, s, n);  return true;
}


// Strings equal?
// in: x, y = two strings
// out: returns true if equal, else false
bool strEq(const char *x, const char *y) {
    return  strcmp(x, y) == 0;
}


// Case-Insensitive Compare Strings
// in: x, y = strings
// out: returns -1 if x<y, 0 if x=y, 1 if x>y
int strICmp(const char *x, const char *y) {
    unsigned char a, b;
    do {
        a = static_cast<unsigned char>(*x++);
        b = static_cast<unsigned char>(*y++);
        if (a>='a' && a<='z')  a -= 'a' - 'A';   // convert a to upper case
        if (b>='a' && b<='z')  b -= 'a' - 'A';   // convert b to upper case
        if (a != b)  return a<b ? -1 : 1;
    } while (a != 0);
    return 0;
}


// Case-Insensitive Strings Equal?
// in: x, y = strings
// out: returns true if x=y, else false
bool strIEq(const char *x, const char *y) { return strICmp(x, y) == 0; }


// Case-Sensitive Starts With
// in: s = string #1
//     substr = string #2
// out: returns true if s starts with substr, else false
bool strStartsWith(const char *s, const char *substr) {
    return memcmp(s, substr, strlen(substr)) == 0;
}


// Case-Sensitive Ends With
// in: s = string #1
//     substr = string #2
// out: returns true if s ends with substr (which is always true if substr is ""), else false
bool strEndsWith(const char *s, const char *substr) {
    size_t m = strlen(s),
           n = strlen(substr);
    return  m >= n  &&  memcmp(s + (m - n), substr, n) == 0;
}


// Case-Insensitive Starts With
// in: s = string #1
//     substr = string #2
// out: returns true if s starts with substr, else false
bool strIStartsWith(const char *s, const char *substr) {
    unsigned char a, b;
    for (;;) {
        a = static_cast<unsigned char>(*s++);
        b = static_cast<unsigned char>(*substr++);
        if (b == 0)  return true;
        if (a>='a' && a<='z')  a -= 'a' - 'A';   // convert a to upper case
        if (b>='a' && b<='z')  b -= 'a' - 'A';   // convert b to upper case
        if (a != b)  return false;
    }
}


// String to uint32_t
// in: s = string of a decimal number, "0x"- or "0X"-prefixed hexadecimal number, or "0b"- or "0B"-prefixed binary number
// out: x = value (=0 if error)
//      returns true if success, false if syntax error
bool strToUInt32(const char *s, uint32_t &x) {
    bool digits = false;
    char c;
    x = 0;
    if (s[0]=='0' && (s[1] | 0x20)=='b') {
        s += 2;
        while ((c = *s++) != 0) {
            if (c=='0' || c=='1')  x = x<<1 | (c - '0');
            else  goto syntax_error;
            digits = true;
        }
    }
    else if (s[0]=='0' && (s[1] | 0x20)=='x') {
        s += 2;
        while ((c = *s++) != 0) {
            if (c>='0' && c<='9')  x = x<<4 | (c - '0');
            else if (c>='A' && c<='F')  x = x<<4 | (c - ('A' - 10));
            else if (c>='a' && c<='f')  x = x<<4 | (c - ('a' - 10));
            else  goto syntax_error;
            digits = true;
        }
    }
    else
        while ((c = *s++) != 0) {
            if (c>='0' && c<='9')  x = 10 * x + (c - '0');
            else  goto syntax_error;
            digits = true;
        }
    if (!digits)  goto syntax_error;
    return true;
    
syntax_error:
    x = 0;
    return false;
}


// String to uint16_t
// in: s = string of a decimal number, "0x"- or "0X"-prefixed hexadecimal number, or "0b"- or "0B"-prefixed binary number
// out: x = value (=0 if error)
//      returns true if success, false if syntax error
bool strToUInt16(const char *s, uint16_t &x) {
    uint32_t y;
    if (strToUInt32(s, y) && y <= 0xFFFF) { x = uint16_t(y);  return true; }
    x = 0;
    return false;
}


// String to int
// in: s = string of a decimal number, "0x"- or "0X"-prefixed hexadecimal number,
//         or "0b"- or "0B"-prefixed binary number, optionally prefixed with a '-'
// out: x = value (=0 if error)
//      returns true if success, false if syntax error
bool strToInt(const char *s, int &x) {
    uint32_t y;
    bool neg = false;
    if (*s == '-') { neg = true;  s++; }
    if (!strToUInt32(s, y)) { x = 0;  return false; }
    x = neg ? -static_cast<int>(y) : static_cast<int>(y);
    return true;
}


// String to double
// in: s = string
// out: x = value (=0.0 if error)
//      returns true if success, false if syntax error
bool strToDbl(const char *s, double &x) {
    if (sscanf(s, "%lf", &x) == 1)  return true;
    x = 0.0;
    return false;
}


// Right Trim
// Remove any trailing whitespace characters.
// in out: s = string
// out: returns length of s after trimming
unsigned strRTrim(char *s) {
    unsigned char *p = reinterpret_cast<unsigned char *>(s);
    unsigned n = strlen(s);
    while (n != 0  &&  p[n - 1] <= ' ')  n--;
    p[n] = 0;
    return n;
}


// Convert a 0xYYMMDDHH timestamp to a string 20YY-MM-DD HHh
// in: t = timestamp in 0xYYMMDDHH format
// out: buf = string buffer (size >=15 bytes)
//      returns buf
char *timestampToStr(uint32_t t, char *buf) {
    sprintf(buf, "20%02X-%02X-%02X %02Xh", t >> 24, t >> 16 & 0xFF, t >> 8 & 0xFF, t & 0xFF);
    return buf;
}


// Catch Ctrl-C (signal SIGINT)
// in: enable = If true, ctrlC will be set to false and will change to true if the Ctrl-C key is pressed.
//              If false, the Ctrl-C key will function normally.
void catchCtrlC(bool enable) {
    static sighandler_t h = SIG_ERR;   // original signal handler, or SIG_ERR if none
    if (enable) {
        if (h == SIG_ERR) {
            h = signal(SIGINT, intHandler);
            if (h == SIG_ERR)  logBug("Cannot Install SIGINT Handler");
        }
        ctrlC = false;
    }
    else {
        if (h != SIG_ERR) { signal(SIGINT, h);  h = SIG_ERR; }
        if (ctrlC)  putchar('\n');
    }
}


// Enable/Disable stdin Buffering & Echo
// in: enable = enable flag: true = stdin buffered & echo on, false = stdin unbuffered & echo off
void bufferStdin(bool enable) {
    static struct termios oldTio;
    static int oldFlags;
    static bool initialized = false,    // oldTio-and-oldFlags-initialized flag
                enabled = true;         // stdin-buffering-enabled flag

    if (!initialized) {
        tcgetattr(STDIN_FILENO, &oldTio);           // get the terminal settings for stdin
        oldFlags = fcntl(STDIN_FILENO, F_GETFL);    // make stdin nonblocking
        initialized = true;
    }

    if (enable && !enabled) {
        tcsetattr(STDIN_FILENO, TCSANOW, &oldTio);  // restore former settings
        fcntl(STDIN_FILENO, F_SETFL, oldFlags);     // restore former flags
        enabled = true;
    }
    else if (!enable && enabled) {
        struct termios newTio = oldTio;
        newTio.c_lflag &= ~ICANON & ~ECHO;          // disable canonical mode (buffered I/O) and local echo
        tcsetattr(STDIN_FILENO, TCSANOW, &newTio);  // set the new settings immediately
        fcntl(STDIN_FILENO, F_SETFL, oldFlags | O_NONBLOCK);
        enabled = false;
    }
}



// ***************
// *  Exception  *
// ***************


// Constructor
// in: fileName = source code file's name
//     funcName = function's name
//     lineNo   = line number in source code (>=1)
//     fmt      = printf-style format string
//     ...      = format string's arguments
Exception::Exception(const char *fileName, const char *funcName, int lineNo, const char *fmt, ...) noexcept {
    this->fileName = fileName;
    this->funcName = funcName;
    this->lineNo   = lineNo;
    va_list args;
    va_start(args, fmt);
    vsnprintf(msg, sizeof msg, fmt, args);
    va_end(args);
}


// Copy Constructor
Exception::Exception(const Exception &x) noexcept {
    fileName = x.fileName;
    funcName = x.funcName;
    lineNo   = x.lineNo;
    strcpy(msg, x.msg);
}


// Assignment Operator
// in: x = value
Exception &Exception::operator=(const Exception &x) noexcept {
    fileName = x.fileName;
    funcName = x.funcName;
    lineNo   = x.lineNo;
    strcpy(msg, x.msg);
    return *this;
}



// ************
// *  Logger  *
// ************

const char *Logger::levelNames[6] = {"DEBUG", "Info", "Warning", "ERROR", "BUG", "CRITICAL"};


// Get Timestamp String
// in: timestampSz = size of timestamp buffer in bytes (should be >=80)
// out: timestamp = timestamp string
void Logger::getTimestamp(char *timestamp, size_t timestampSz) {
    timespec t;
    struct tm T;
    if (clock_gettime(CLOCK_REALTIME, &t)) {
        logBug("clock_gettime(CLOCK_REALTIME,&t) Failed");
        bzero(&t, sizeof t);
    }
    localtime_r(&t.tv_sec, &T);
    strftime(timestamp, timestampSz, "%Y-%m-%d %H:%M:%S", &T);
    size_t n = strlen(timestamp);
    snprintf(timestamp + n, timestampSz - n, ".%06u", static_cast<unsigned>(t.tv_nsec / 1000));
}


// Level -> String
// in: level = level enumeration
// out: returns string representation
const char *Logger::level2str(Level level) { return levelNames[level]; }


// String -> Level
// in: s = string (typically one of levelNames[]; may be abbreviated to first few characters; case insensitive)
// out: level = corresponding level if success, else DEBUG
//      returns true if success, else false
bool Logger::str2level(const char *s, Level &level) {
    for (unsigned i = 0; i < (sizeof levelNames)/sizeof(levelNames[0]); i++)
        if (strIStartsWith(levelNames[i], s)) { level = static_cast<Level>(i);  return true; }
    level = DEBUG;  return false;
}


// Constructor
Logger::Logger() {
    hFile = nullptr;
    filename[0] = 0;
    fileLevel = DEBUG;
    stderrLevel = WARNING;
}


// Destructor
Logger::~Logger() {
    closeLogFile();
}


// Check if logger would print or write to file a DEBUG message
bool Logger::wantsDebug() { return stderrLevel<=DEBUG || fileLevel<=DEBUG; }


// Close Log File, If Open
void Logger::closeLogFile() {
    if (hFile != nullptr) { fclose(hFile);  hFile = nullptr; }
    filename[0] = 0;
}


// Set Severity Level of Messages to Write to File
// in: levelName = string (typically one of levelNames[]; may be abbreviated to first few characters; case insensitive)
//     fn = log file's path, or nullptr to close the log file
// throws: Exception
void Logger::log2file(const char *levelName, const char *fn) {
    Level level;
    closeLogFile();
    if (!str2level(levelName, level))  throwException("Unknown Log Level \"%s\"", levelName);
    fileLevel = level;
    if (fn != nullptr && *fn != 0) {
        hFile = fopen(fn, "w");
        if (hFile == nullptr)  throwException("Cannot Create Log File: %s", fn);
        strCpy(filename, sizeof filename, fn);
    }
}


// Set Severity Level of Messages to Print to stderr
// in: levelName = string (typically one of levelNames[]; may be abbreviated to first few characters; case insensitive)
// out: returns true if success, false if invalid levelName
bool Logger::log2stderr(const char *levelName) {
    Level level;
    if (!str2level(levelName, level))  return false;
    stderrLevel = level;  return true;
}


// Report a Debug, Informational, Warning, Error, Bug, or Critical Message
// Note, if a bug or critical message, this function does not return; it exits the program.
// The message text (fmt, ...) may be multiple lines separated by '\n'; any final '\n' will be ignored.
// instance in: hFile, fileLevel, stderrLevel
// in: fileName, funcName, lineNo = caller's source-code location
//     type = message type
//     fmt = printf-style format for error message
//     ... = fmt's arguments
void Logger::report(const char *fileName, const char *funcName, int lineNo, Level type, const char *fmt, ...) {
    static const char INDENT[] = "    ";
    if (type >= fileLevel || type >= stderrLevel || type == BUG || type == CRITICAL) {

        // get timestamp
        char timestamp[80];
        getTimestamp(timestamp, sizeof timestamp);
        
        // create message
        char msg[1024];
        va_list args;
        va_start(args, fmt);
        vsnprintf(msg, sizeof msg, fmt, args);
        va_end(args);

        // print message if severe enough
        if (type >= stderrLevel || type == BUG || type == CRITICAL) {
            fprintf(stderr, "[%s] %s  reported by %s() at %s:%d\n",
                timestamp, levelNames[type], funcName, fileName, lineNo);
            if (strchr(msg, '\n') == nullptr)  fprintf(stderr, "%s%s\n", INDENT, msg);
            else {
                bool blank = true;   // line-is-empty flag
                char c;
                for (const char *p = msg; (c = *p) != 0; p++) {
                    if (c == '\n')  blank = true;
                    else if (blank) { fprintf(stderr, "%s", INDENT);  blank = false; }
                    fputc(c, stderr);
                }
                if (!blank)  fputc('\n', stderr);
            }
        }

        // write message to log file if severe enough
        if ((type >= fileLevel || type == BUG || type == CRITICAL) && hFile != nullptr) {
            fprintf(hFile, "[%s] %s  reported by %s() at %s:%d\n",
                timestamp, levelNames[type], funcName, fileName, lineNo);
            if (strchr(msg, '\n') == nullptr)  fprintf(hFile, "%s%s\n", INDENT, msg);
            else {
                bool blank = true;   // line-is-empty flag
                char c;
                for (const char *p = msg; (c = *p) != 0; p++) {
                    if (c == '\n')  blank = true;
                    else if (blank) { fprintf(hFile, "%s", INDENT);  blank = false; }
                    fputc(c, hFile);
                }
                if (!blank)  fputc('\n', hFile);
            }
        }

        // exit program if BUG or CRITICAL message
        if (type == BUG || type == CRITICAL) {
            bufferStdin(true);
            exit(EXIT_FAILURE);
        }
    }
}



// ***************
// *  Stopwatch  *
// ***************
//
// Uses Linux' monotonic clock to measure time

// Get Current Time
// out: returns current time in seconds since power up
double Stopwatch::now() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
  return  static_cast<double>(ts.tv_sec) + 1e-9 * static_cast<double>(ts.tv_nsec);
}


// Constructor
Stopwatch::Stopwatch() { T0 = now(); }


// Reset
void Stopwatch::reset() { T0 = now(); }


// Get Elapsed Time
// out: returns seconds since the last call to reset() or this class' constructor
double Stopwatch::elapsed() { return  now() - T0; }



// *******************************
// *  High Resolution Stopwatch  *
// *******************************
//
// Uses PL's Strobe Generator block to measure time to 10 ns resolution


// Constructor
Stopwatch2::Stopwatch2() { T0 = peripherals.dap.usTime(); }


// Reset
void Stopwatch2::reset() { T0 = peripherals.dap.usTime(); }


// Get Elapsed Time
// out: returns seconds since the last call to reset() or this class' constructor
double Stopwatch2::elapsed() { return  (peripherals.dap.usTime() - T0) * 1e-6; }


// Test of us Microseconds Has Elapsed
// in: us = duration in microseconds
// out: returns true if >=us microseconds has elapsed, else false
bool Stopwatch2::hasElapsed(uint32_t us) { return  peripherals.dap.usTime() - T0 >= us; }
