CXX = g++
CXXFLAGS = -c -std=c++0x -Wall -Werror -fpic -Wno-return-type-c-linkage

all: libcasacorewrapper.so

tables.o: tables.cpp
	$(CXX) $(CXXFLAGS) tables.cpp

measures.o: measures.cpp
	$(CXX) $(CXXFLAGS) measures.cpp

libcasacorewrapper.so: tables.o measures.o
	$(CXX) -shared -o libcasacorewrapper.so tables.o measures.o -lcasa_tables -lcasa_measures

clean:
	-rm *.o
	-rm *.so

install:
	cp libcasacorewrapper.so ..

