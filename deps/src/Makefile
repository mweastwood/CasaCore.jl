CXX = g++
CXXFLAGS = -c -Wall -Werror -fpic

CASACORE = ../casacore

all: libcasacorewrapper.so

containers.o: containers.cpp containers.h
	$(CXX) $(CXXFLAGS) containers.cpp -I$(CASACORE)

tables.o: tables.cpp
	$(CXX) $(CXXFLAGS) tables.cpp -I$(CASACORE)

quanta.o: quanta.cpp
	$(CXX) $(CXXFLAGS) quanta.cpp -I$(CASACORE)

frame.o: frame.cpp
	$(CXX) $(CXXFLAGS) frame.cpp -I$(CASACORE)

epoch.o: epoch.cpp
	$(CXX) $(CXXFLAGS) epoch.cpp -I$(CASACORE)

direction.o: direction.cpp
	$(CXX) $(CXXFLAGS) direction.cpp -I$(CASACORE)

position.o: position.cpp
	$(CXX) $(CXXFLAGS) position.cpp -I$(CASACORE)

libcasacorewrapper.so: containers.o tables.o quanta.o frame.o epoch.o direction.o position.o
	$(CXX) -shared -o libcasacorewrapper.so containers.o tables.o quanta.o frame.o epoch.o direction.o position.o -lcasa_tables -lcasa_measures

clean:
	-rm *.o
	-rm *.so

install:
	cp libcasacorewrapper.so ..

