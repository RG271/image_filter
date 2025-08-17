#ifndef _APP_H
#define _APP_H

// Control Utility
//
// author: Dr. Richard D. Kaminsky
// dated:  2/9/2023


#define APP_TITLE        "Control Utility"    // C++ application's title
#define APP_AUTHOR       "Richard Kaminsky"   // C++ application's author
#define APP_DATE         "2/9/2023"           // C++ application's build date in month/day/year format
#define APP_FILE         "app"                // C++ application's executable file
#define APP_FW_BIN       "control.bin"        // firmware file -- Programmable Logic (PL) configuration file in Xilinx .BIT.BIN format
#define APP_FW_CREATION  0x23010314           // APP_FW_BIN's creation time (YYMMDDHH binary-coded-decimal format) -- fw's universally unique identifier
#define APP_FW_BUILD     0x23011016           // APP_FW_BIN's build time (YYMMDDHH binary-coded-decimal format) -- fw's version number


#endif
