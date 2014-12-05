all: libcasacorewrapper.so

containers.o: containers.cpp containers.h
	g++ -c -Wall -Werror -fpic containers.cpp -I/scr2/mweastwood/software/casacore-1.7.0

tableswrapper.o: tableswrapper.cpp
	g++ -c -Wall -Werror -fpic tableswrapper.cpp -I/scr2/mweastwood/software/casacore-1.7.0

measureswrapper.o: measureswrapper.cpp
	g++ -c -Wall -Werror -fpic measureswrapper.cpp -I/scr2/mweastwood/software/casacore-1.7.0

libcasacorewrapper.so: containers.o tableswrapper.o measureswrapper.o
	g++ -shared -o libcasacorewrapper.so containers.o tableswrapper.o measureswrapper.o -lcasa_tables -lcasa_measures

clean:
	rm containers.o
	rm tableswrapper.o
	rm measureswrapper.o
	rm libcasacorewrapper.so

