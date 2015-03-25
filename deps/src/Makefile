CXX = g++
CXXFLAGS = -c -Wall -Werror -fpic

CASACORE = ../downloads/casacore-1.7.0

all: libcasacorewrapper.so

containers.o: containers.cpp containers.h
	$(CXX) $(CXXFLAGS) containers.cpp -I$(CASACORE)

tableswrapper.o: tableswrapper.cpp
	$(CXX) $(CXXFLAGS) tableswrapper.cpp -I$(CASACORE)

measureswrapper.o: measureswrapper.cpp
	$(CXX) $(CXXFLAGS) measureswrapper.cpp -I$(CASACORE)

libcasacorewrapper.so: containers.o tableswrapper.o measureswrapper.o
	$(CXX) -shared -o libcasacorewrapper.so containers.o tableswrapper.o measureswrapper.o -lcasa_tables -lcasa_measures

clean:
	-rm *.o
	-rm *.so

install:
	cp libcasacorewrapper.so ..

