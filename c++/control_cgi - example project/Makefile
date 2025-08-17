# Makefile
#
# author: Richard Kaminsky
# date:   2/9/2023

.PHONY: all clean

EXE := app

HDRS := $(EXE).h command.h common.h peripherals.h

OBJS := $(EXE).o command.o common.o peripherals.o

CXX := g++

CXXFLAGS := -std=gnu++17


all: $(EXE)


clean:
	rm -f $(OBJS) $(EXE)


$(EXE): $(OBJS)
#	$(CXX) $(OBJS) -lpthread -lm -o $@
	$(CXX) $(OBJS) -o $@
# Copy executable file to website's cgi-bin directory and set ownership/permissions
	sudo cp $(EXE)       /var/www/cgi-bin/control
	sudo chgrp www-data  /var/www/cgi-bin/control
	sudo chmod u+s       /var/www/cgi-bin/control
# Set executable file's ownership/permissions
	sudo chown root $(EXE)
	sudo chmod u+s $(EXE)

$(EXE).o: $(EXE).cpp $(HDRS)
	$(CXX) -c $(CXXFLAGS) $(EXE).cpp -o $(EXE).o

command.o: command.cpp $(HDRS)
	$(CXX) -c $(CXXFLAGS) command.cpp -o command.o

common.o: common.cpp $(HDRS)
	$(CXX) -c $(CXXFLAGS) common.cpp -o common.o

peripherals.o: peripherals.cpp $(HDRS)
	$(CXX) -c $(CXXFLAGS) peripherals.cpp -o peripherals.o
