#include <cstring>
#include "app.h"
#include "peripherals.h"
#include "common.h"
#include "command.h"

// -----  Command Handlers for CGI HTTP GET & POST's  -----


// HTML Response Template's Parameters for cmdGetDACsForm() or cmdSetDACs()
struct Template1_Params {
    const char *author,     // application's author (NUL-terminated string; should be APP_AUTHOR)
               *date;       // application's date (NUL-terminated string; should be APP_DATE)
    double  wavelength_a,   // Wavelength A  (0.0 to 9999.0 nm)
            wavelength_b;   // Wavelength B  (0.0 to 9999.0 nm)
    int  duration_a,        // Duration A    (10..1048575 us)
         duration_b,        // Duration B    (10..1048575 us)
         soa_a,             // SOA A         (0..4095 DAC_counts)
         soa_b,             // SOA B         (0..4095 DAC_counts)
         gain_a,            // Gain A        (0..4095 DAC_counts)
         gain_b,            // Gain B        (0..4095 DAC_counts)
         phase_a,           // Phase A       (0..4095 DAC_counts)
         phase_b,           // Phase B       (0..4095 DAC_counts)
         left_a,            // Left A        (0..4095 DAC_counts)
         left_b,            // Left B        (0..4095 DAC_counts)
         right_a,           // Right A       (0..4095 DAC_counts)
         right_b;           // Right B       (0..4095 DAC_counts)
};


// HTML Response Template for cmdGetDACsForm() or cmdSetDACs()
static const char Template1_Text[] = R"DOC(<!DOCTYPE html>
<html>

    <head>
    <meta name="description" content="Web form for updating optical beacon's parameters and enabling the beacon">
    <meta name="author" content="%s">
    <meta name="date" content="%s">
    <meta charset="UTF-8">
    <title>Beacon Generator</title>

    <!-- <link rel="stylesheet" type="text/css" href="theme.css"> -->
    <style>

    body {
        padding-left: 1em;
        padding-right: 1em;
        font-family: "Times New Roman", Georgia, serif;
    }

    h1 {
        font-family: "Arial", sans-serif;
        text-align: center;
    }

    h2 {
        font-family: "Arial", sans-serif;
        text-align: center;
    }

    p {
        font-size: 12pt;
    }

    pre {
        font-family: "Courier New", monospace;
        font-size: 9pt;
    }

    table.dacs {
        border-collapse: collapse;
        margin-left: auto;
        margin-right: auto;
    }

    table.dacs td {
        padding: 0 8px 6px 8px;
    }

    table.dacs th {
        padding: 0 8px 8px 8px;
    }

    .comment {
        font-family: "Arial", sans-serif;
        font-size: 10pt;
    }

    </style>

    </head>


    <body>

    <h1 style="padding-bottom:20px">Educational Lasercom Demo</h1>

    <div>
        <form action="https://%s/cgi-bin/beacon" method="post">
             <input type="hidden" name="command" value="setDACs">
             <table class="dacs">
                 <tr>
                     <th>Name</th>
                     <th>WL A</th>
                     <th>WL B</th>
                     <th>Comments</th>
                 </tr>
                 <tr>
                     <td>Wavelength</td>
                     <td><input type="text" name="wavelength_a" value="%.4f"></td>
                     <td><input type="text" name="wavelength_b" value="%.4f"></td>
                     <td class="comment">nm</td>
                 </tr>
                 <tr>
                     <td>Durations</td>
                     <td><input type="text" name="duration_a" value="%d"></td>
                     <td><input type="text" name="duration_b" value="%d"></td>
                     <td class="comment">10..1048575 &mu;s</td>
                 </tr>
                 <tr>
                     <td>SOA</td>
                     <td><input type="text" name="soa_a" value="%d"></td>
                     <td><input type="text" name="soa_b" value="%d"></td>
                     <td class="comment">0..4095 DAC_counts</td>
                 </tr>
                 <tr>
                     <td>Gain</td>
                     <td><input type="text" name="gain_a" value="%d"></td>
                     <td><input type="text" name="gain_b" value="%d"></td>
                     <td class="comment">0..4095 DAC_counts</td>
                 </tr>
                 <tr>
                     <td>Phase</td>
                     <td><input type="text" name="phase_a" value="%d"></td>
                     <td><input type="text" name="phase_b" value="%d"></td>
                     <td class="comment">0..4095 DAC_counts</td>
                 </tr>
                 <tr>
                     <td>Left Mirror</td>
                     <td><input type="text" name="left_a" value="%d"></td>
                     <td><input type="text" name="left_b" value="%d"></td>
                     <td class="comment">0..4095 DAC_counts</td>
                 </tr>
                 <tr>
                     <td>Right Mirror</td>
                     <td><input type="text" name="right_a" value="%d"></td>
                     <td><input type="text" name="right_b" value="%d"></td>
                     <td class="comment">0..4095 DAC_counts</td>
                 </tr>
             </table>
             <div style="margin-top: 16px; text-align: center">
                 <input type="submit" name="submit" value="Set" style="font-weight:bold; width:13em"> &nbsp; &nbsp;
                 <input type="reset" name="reset" value="  Reset Form to Default Values  ">
             </div>
        </form>
    </div>

    <p style="text-align:center">
        <br><br><br><br><br><br>
        This website is hosted by a <a target="_blank" href="https://www.tulembedded.com/FPGA/ProductsPYNQ-Z2.html">PYNQ-Z2 FPGA board</a>.
        It is running a <a target="_blank" href="http://www.pynq.io/board.html">PYNQ-Z2 v3.0.1 image</a> with
        <a target="_blank" href="https://www.nginx.com">Nginx</a>/<a target="_blank" href="https://www.php.net">PHP</a>/<a target="_blank" href="https://www.nginx.com/resources/wiki/start/topics/examples/fastcgiexample">FastCGI</a> web server.
        <br>
        For help contact Richard Kaminsky.
    </p>

    <p style="text-align:right; font-size:11pt">
        <br>
        The PYNQ-Z2's time is %s<br>
        <a target="_blank" href="http://%s:9090">Log into Jupyter Notebook...</a><br>
        <span style="color:silver">Client's IP Address: %s</span>
    </p>


    </body>

</html>
)DOC";


/*
void cmdDebug(CgiRequest &cgi) {
    printf("Content-Type: text/plain\n");
    putchar('\n');
    printf("Read %zu bytes from stdin\n", cgi.urlEncSz);
    printf("CONTENT_LENGTH  =  \"%s\"  =  %u\n", cgi.contentLength, cgi.contentLen);
    printf("CONTENT_TYPE    =  \"%s\"\n", cgi.contentType);
    printf("QUERY_STRING    =  \"%s\"\n", cgi.queryString);
    printf("REMOTE_ADDR     =  \"%s\"\n", cgi.remoteAddr);
    printf("REQUEST_METHOD  =  \"%s\"\n", cgi.requestMethod);
    printf("------- Read -------\n%s%s--------------------\n", cgi.urlEnc, strEndsWith(cgi.urlEnc, "\n") ? "" : "\n");
}
*/


// Get Form Field with Integer Value in 0..4095
// in: cgi = CgiRequest object
//     key = form field's name
//     name = form field's human-readable name (displayed in exception messages)
//     xmin = minimum value
//     xmax = maximum value
// out: returns value in 0..4095 or throws an Exception
static int getInt(const CgiRequest &cgi, const char *key, const char *name, int xmin, int xmax) {
    int x;
    if (!cgi.get(key, x) || x < xmin || x > xmax)  throwException("%s's field is not an integer in the range %d..%d", name, xmin, xmax);
    return x;
}


// Get Form Field with Integer Value in 0..4095
// in: cgi = CgiRequest object
//     key = form field's name
//     name = form field's human-readable name (displayed in exception messages)
// out: returns value in 0..4095 or throws an Exception
static int getU12(const CgiRequest &cgi, const char *key, const char *name) {
    return getInt(cgi, key, name, 0, 4095);
}


// Get Form Field with Double Value
// in: cgi = CgiRequest object
//     key = form field's name
//     name = form field's human-readable name (displayed in exception messages)
//     xmax = maximum value (ignored if xmax < xmin)
//     xmin = minimum value (ignored if xmax < xmin)
// out: returns value or throws an Exception
static double getDbl(const CgiRequest &cgi, const char *key, const char *name, double xmax = -1.0, double xmin = 0.0) {
    double x;
    if (!cgi.get(key, x))  throwException("%s's field is not a floating-point number", name);
    if (xmax >= xmin && (x < xmin || x > xmax))  throwException("%s's field out of range [%g, %g]", name, xmin, xmax);
    return x;
}


// Print HTML Response for cmdGetDACsForm() or cmdSetDACs()
static void respond(const CgiRequest &cgi, const Template1_Params &params) {
    char date[24];
    getDateTime(date, sizeof date);         // get the date and time now
    printf("Content-Type: text/html\n");
    putchar('\n');
    printf( Template1_Text,
            params.author,
            params.date,
            cgi.serverAddr2,
            params.wavelength_a,  params.wavelength_b,
            params.duration_a,    params.duration_b,
            params.soa_a,         params.soa_b,
            params.gain_a,        params.gain_b,
            params.phase_a,       params.phase_b,
            params.left_a,        params.left_b,
            params.right_a,       params.right_b,
            date,
            cgi.serverAddr2,
            cgi.remoteAddr   );
}


// Get "setDACs" Web Form with Default Values
// in: cgi = CgiRequest object, where cgi.get("command", buf, bufSz) returns "setDACs"
void cmdGetDACsForm(const CgiRequest &cgi) {
    Template1_Params params;

    // default form values
    bzero(&params, sizeof params);

    params.author       = APP_AUTHOR;
    params.date         = APP_DATE;

    params.wavelength_a = 1234.0001;
    params.duration_a   = 512;
    params.soa_a        = 1001;
    params.gain_a       = 1002;
    params.phase_a      = 1003;
    params.left_a       = 1004;
    params.right_a      = 1005;

    params.wavelength_b = 1100.0;
    params.duration_b   = 567;
    params.soa_b        = 2001;
    params.gain_b       = 2002;
    params.phase_b      = 2003;
    params.left_b       = 2004;
    params.right_b      = 2005;
    
    // print HTTP response (an HTML page)
    respond(cgi, params);
}


// Handle "setDACs" Command
// in: cgi = CgiRequest object, where cgi.get("command", buf, bufSz) returns "setDACs"
// out: raises an Exception if missing field or field out of range
void cmdSetDACs(const CgiRequest &cgi) {
    Template1_Params params;
    
    // parse HTTP request (URL-encoded string of HTML form data)
    bzero(&params, sizeof params);

    params.author       = APP_AUTHOR;
    params.date         = APP_DATE;

    params.wavelength_a = getDbl( cgi, "wavelength_a", "Wavelength A", 9999.0 );
    params.duration_a   = getInt( cgi, "duration_a",   "Duration A",  10, 1048575 );
    params.soa_a        = getU12( cgi, "soa_a",        "SOA A"   );
    params.gain_a       = getU12( cgi, "gain_a",       "Gain A"  );
    params.phase_a      = getU12( cgi, "phase_a",      "Phase A" );
    params.left_a       = getU12( cgi, "left_a",       "Left A"  );
    params.right_a      = getU12( cgi, "right_a",      "Right A" );

    params.wavelength_b = getDbl( cgi, "wavelength_b", "Wavelength B", 9999.0 );
    params.duration_b   = getInt( cgi, "duration_b",   "Duration B",  10, 1048575 );
    params.soa_b        = getU12( cgi, "soa_b",        "SOA B"   );
    params.gain_b       = getU12( cgi, "gain_b",       "Gain B"  );
    params.phase_b      = getU12( cgi, "phase_b",      "Phase B" );
    params.left_b       = getU12( cgi, "left_b",       "Left B"  );
    params.right_b      = getU12( cgi, "right_b",      "Right B" );

    // set Durations
    peripherals.beacon.setWlaDuration( params.duration_a );
    peripherals.beacon.setWlbDuration( params.duration_b );

    // set DACs
    peripherals.beacon.setModeNormal();
    peripherals.beacon.setDac( 4, params.soa_a,   params.soa_b   );
    peripherals.beacon.setDac( 3, params.gain_a,  params.gain_b  );
    peripherals.beacon.setDac( 2, params.phase_a, params.phase_b );
    peripherals.beacon.setDac( 1, params.left_a,  params.left_b  );
    peripherals.beacon.setDac( 0, params.right_a, params.right_b );
    
    // print HTTP response (an HTML page)
    respond(cgi, params);
}
