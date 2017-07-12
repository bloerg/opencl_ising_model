export CPLUS_INCLUDE_PATH=/opt/intel/opencl/include
export LIBRARY_PATH=/opt/intel/opencl

HEADERS=cl.hpp
SOURCES=Ising.cpp

ifeq ($(CONFIG),debug)
	OPT =-O0 -g
else
	OPT =
endif

all: ising

ising: $(HEADERS) $(SOURCES) Makefile
	g++ $(SOURCES) -I ./ -lOpenCL -oIsing -std=gnu++0x $(OPT)

clean:
	rm -f Ising

