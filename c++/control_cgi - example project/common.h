#ifndef _COMMON_H
#define _COMMON_H

#include <cstdint>
#include <cstdio>
#include <exception>


// ***************
// *  Functions  *
// ***************

int      clamp(int x, int lo, int hi);
unsigned clamp(unsigned x, unsigned lo, unsigned hi);
double   clamp(double x, double lo, double hi);

const char *getEnv(const char *name, bool *success = nullptr);
char *getDateTime(char *buf, size_t bufSz);
bool strCpy(char *buf, size_t bufSz, const char *s);
bool strEq(const char *x, const char *y);
int strICmp(const char *x, const char *y);
bool strIEq(const char *x, const char *y);
bool strStartsWith(const char *s, const char *substr);
bool strEndsWith(const char *s, const char *substr);
bool strIStartsWith(const char *s, const char *substr);
bool strToUInt32(const char *s, uint32_t &x);
bool strToUInt16(const char *s, uint16_t &x);
bool strToInt(const char *s, int &x);
bool strToDbl(const char *s, double &x);
unsigned strRTrim(char *s);
char *timestampToStr(uint32_t t, char *buf);

// Terminal Control
extern volatile bool ctrlC;
void catchCtrlC(bool enable);
void bufferStdin(bool enable);


// ***************
// *  Exception  *
// ***************

class Exception: public std::exception {
public:
    const char *fileName,   // source code file in which the exception occurred (string)
               *funcName;   // function name in which the exception occurred (string)
    int lineNo;             // line number in source code (>=1)
    char msg[200];          // text message (string)
    explicit Exception(const char *fileName, const char *funcName, int lineNo, const char *fmt, ...) noexcept;
    Exception(const Exception &x) noexcept;
    Exception &operator=(const Exception &x) noexcept;
    const char *what() const noexcept override { return msg; }     // override exception::what()
};

#define throwException(fmt, ...)    throw Exception(__FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)


// ************
// *  Logger  *
// ************

// Logger
// Singleton class for reporting information, warnings, errors, and critical errors. Not thread safe.
class Logger {
public:
    enum Level {
        DEBUG    = 0,   // debug message
        INFO     = 1,   // information
        WARNING  = 2,   // warning
        ERR      = 3,   // nonfatal error
        BUG      = 4,   // fatal error due to a software bug; this will terminate the program
        CRITICAL = 5    // fatal error not due to a software bug; this will terminate the program
    };
private:
    static const char *levelNames[6];   // string names of Level values
    FILE *hFile;                        // open log file for output, or nullptr if none
    char filename[256];                 // hFile's path, or "" if hFile==nullptr
    static void getTimestamp(char *timestamp, size_t timestampSz);
public:
    static const char *level2str(Level level);
    static bool str2level(const char *s, Level &level);
    Level fileLevel,    // only messages this severe or greater will be logged to hFile
          stderrLevel;  // only messages this severe or greater will be logged to stderr
    bool wantsDebug();
    void closeLogFile();
    void log2file(const char *levelName, const char *fn = nullptr);
    bool log2stderr(const char *levelName);
    Logger();
    Logger(const Logger &) = delete;
    ~Logger();
    Logger &operator=(const Logger &) = delete;
    void report(const char *fileName, const char *funcName, int lineNo, Level type, const char *fmt, ...);
};

extern Logger logger;

#define logDebug(fmt, ...)      logger.report(__FILE__, __FUNCTION__, __LINE__, Logger::DEBUG,    fmt, ##__VA_ARGS__)
#define logDebug2(caption, sb)  logger.report2(__FILE__, __FUNCTION__, __LINE__, Logger::DEBUG, caption, sb)
#define logInfo(fmt, ...)       logger.report(__FILE__, __FUNCTION__, __LINE__, Logger::INFO,     fmt, ##__VA_ARGS__)
#define logWarning(fmt, ...)    logger.report(__FILE__, __FUNCTION__, __LINE__, Logger::WARNING,  fmt, ##__VA_ARGS__)
#define logError(fmt, ...)      logger.report(__FILE__, __FUNCTION__, __LINE__, Logger::ERR,      fmt, ##__VA_ARGS__)
#define logBug(fmt, ...)        logger.report(__FILE__, __FUNCTION__, __LINE__, Logger::BUG,      fmt, ##__VA_ARGS__)
#define logCritical(fmt, ...)   logger.report(__FILE__, __FUNCTION__, __LINE__, Logger::CRITICAL, fmt, ##__VA_ARGS__)


// *****************
// *  Stopwatches  *
// *****************

// Linux Monotonic Clock Stopwatch
class Stopwatch {
private:
    double T0;
    static double now();
public:
    Stopwatch();
    Stopwatch(const Stopwatch &) = delete;                // delete copy constructor
    Stopwatch &operator=(const Stopwatch &) = delete;     // delete assignment operator
    void reset();
    double elapsed();
    bool hasElapsed(double T) { return elapsed() >= T; }
};

// 1us Resolution Stopwatch
class Stopwatch2 {
private:
    uint32_t T0;
public:
    Stopwatch2();
    Stopwatch2(const Stopwatch2 &) = delete;              // delete copy constructor
    Stopwatch2 &operator=(const Stopwatch2 &) = delete;   // delete assignment operator
    void reset();
    double elapsed();
    bool hasElapsed(uint32_t us);
};


// *****************
// *  CGI Request  *
// *****************

// CGI Request
class CgiRequest {
public:
    static constexpr size_t MAX_URLENC_SIZE = 8192;
    char *urlEnc;                   // pointer to buffer on the heap of POST or GET URL-encoded data, NUL terminated (= nullptr if none)
    size_t urlEncSz;                // number of bytes (>=0) in urlEnc buffer, or 0 if no buffer
    const char *contentLength,      // HTTP Content Length in bytes as a decimal string
               *contentType,        // HTTP Content Type (e.g., "application/x-www-form-urlencoded")
               *queryString,        // GET query string (= "" if none)
               *remoteAddr,         // client's IP address (e.g., "192.168.2.1")
               *requestMethod,      // HTTP Request Method (e.g., "GET" or "POST")
               *serverAddr;         // server's IP address (e.g., "192.168.2.99")
    char serverAddr2[64];           // server's IP address if it is "192.168.2.99"; otherwise, server's hostname (/etc/hostname file's contents stripped of trailing whitespace)
    unsigned contentLen;            // HTTP Content Length in bytes
    CgiRequest();
    CgiRequest(const CgiRequest &) = delete;                // delete copy constructor
    CgiRequest &operator=(const CgiRequest &) = delete;     // delete assignment operator
    ~CgiRequest();
    void init();
    bool get(const char *key, char *buf, size_t bufSz) const;
    bool get(const char *key, int &value) const;
    bool get(const char *key, double &value) const;
};



#endif
