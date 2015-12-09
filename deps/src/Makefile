CXX = g++
CXXFLAGS = -c -Wall -Werror -fpic

CASACORE = ../casacore

all: libcasacorewrapper.so

containers.o: containers.cpp containers.h
	$(CXX) $(CXXFLAGS) containers.cpp -I$(CASACORE)

tables.o: tables.cpp
	$(CXX) $(CXXFLAGS) tables.cpp -I$(CASACORE)

measures.o: measures.cpp
	$(CXX) $(CXXFLAGS) measures.cpp -I$(CASACORE)

libcasacorewrapper.so: containers.o tables.o measures.o
	$(CXX) -shared -o libcasacorewrapper.so containers.o tables.o measures.o -lcasa_tables -lcasa_measures

clean:
	-rm *.o
	-rm *.so

install:
	cp libcasacorewrapper.so ..

