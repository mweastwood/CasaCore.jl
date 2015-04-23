CXX = g++
CXXFLAGS = -c -Wall -Werror -fpic

CASACORE = ../downloads/casacore-1.7.0

all: libcasacorewrapper.so

containers.o: containers.cpp containers.h
	$(CXX) $(CXXFLAGS) containers.cpp -I$(CASACORE)

tables.o: tables.cpp
	$(CXX) $(CXXFLAGS) tables.cpp -I$(CASACORE)

quanta.o: quanta.cpp
	$(CXX) $(CXXFLAGS) quanta.cpp -I$(CASACORE)

measures.o: measures.cpp
	$(CXX) $(CXXFLAGS) measures.cpp -I$(CASACORE)

epoch.o: epoch.cpp
	$(CXX) $(CXXFLAGS) epoch.cpp -I$(CASACORE)

direction.o: direction.cpp
	$(CXX) $(CXXFLAGS) direction.cpp -I$(CASACORE)

position.o: position.cpp
	$(CXX) $(CXXFLAGS) position.cpp -I$(CASACORE)

libcasacorewrapper.so: containers.o tables.o quanta.o measures.o epoch.o direction.o position.o
	$(CXX) -shared -o libcasacorewrapper.so containers.o tables.o quanta.o measures.o epoch.o direction.o position.o -lcasa_tables -lcasa_measures

clean:
	-rm *.o
	-rm *.so

install:
	cp libcasacorewrapper.so ..

