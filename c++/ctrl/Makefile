# Makefile
#
# author: Richard Kaminsky
# date:   7/28/2025

.PHONY: all clean

EXE := app

HDRS := $(EXE).h common.h peripherals.h

OBJS := $(EXE).o common.o peripherals.o

CXX := g++

CXXFLAGS := -std=gnu++17


all: $(EXE)


clean:
	rm -f $(OBJS) $(EXE)


$(EXE): $(OBJS)
#	$(CXX) $(OBJS) -lpthread -lm -o $@
	$(CXX) $(OBJS) -o $@
# Set executable file's ownership/permissions
#	sudo chown root $(EXE)
#	sudo chmod u+s $(EXE)

$(EXE).o: $(EXE).cpp $(HDRS)
	$(CXX) -c $(CXXFLAGS) $(EXE).cpp -o $(EXE).o

common.o: common.cpp $(HDRS)
	$(CXX) -c $(CXXFLAGS) common.cpp -o common.o

peripherals.o: peripherals.cpp $(HDRS)
	$(CXX) -c $(CXXFLAGS) peripherals.cpp -o peripherals.o
