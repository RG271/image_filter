#ifndef _COMMAND_H
#define _COMMAND_H

#include "common.h"


// Command Handlers for CGI HTTP GET & POST's

void cmdGetDACsForm(const CgiRequest &cgi);
void cmdSetDACs(const CgiRequest &cgi);


#endif
