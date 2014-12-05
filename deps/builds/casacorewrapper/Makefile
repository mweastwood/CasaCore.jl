CXX = g++
CXXFLAGS = -c -Wall -Werror -fpic

CASACORE = ../../src/casacore-1.7.0
SRCDIR = ../../src/casacorewrapper
PREFIX = ../../usr

all: libcasacorewrapper.so

containers.o: $(SRCDIR)/containers.cpp $(SRCDIR)/containers.h
	$(CXX) $(CXXFLAGS) $(SRCDIR)/containers.cpp -I$(CASACORE)

tableswrapper.o: $(SRCDIR)/tableswrapper.cpp
	$(CXX) $(CXXFLAGS) $(SRCDIR)/tableswrapper.cpp -I$(CASACORE)

measureswrapper.o: $(SRCDIR)/measureswrapper.cpp
	$(CXX) $(CXXFLAGS) $(SRCDIR)/measureswrapper.cpp -I$(CASACORE)

libcasacorewrapper.so: containers.o tableswrapper.o measureswrapper.o
	$(CXX) -shared -o libcasacorewrapper.so containers.o tableswrapper.o measureswrapper.o -L$(PREFIX)/lib -lcasa_tables -lcasa_measures

clean:
	rm *.o
	rm *.so

install:
	mkdir -p $(PREFIX)/lib
	cp libcasacorewrapper.so $(PREFIX)/lib

