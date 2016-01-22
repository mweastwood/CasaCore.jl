CXX = g++
CXXFLAGS = -c -Wall -Werror -fpic

all: libcasacorewrapper.so

tables.o: tables.cpp
	$(CXX) $(CXXFLAGS) tables.cpp -I/usr/include/casacore

measures.o: measures.cpp
	$(CXX) $(CXXFLAGS) measures.cpp -I/usr/include/casacore

libcasacorewrapper.so: tables.o measures.o
	$(CXX) -shared -o libcasacorewrapper.so tables.o measures.o -lcasa_tables -lcasa_measures

clean:
	-rm *.o
	-rm *.so

install:
	cp libcasacorewrapper.so ..

