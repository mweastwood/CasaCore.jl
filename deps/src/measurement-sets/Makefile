CXX = g++
CXXFLAGS = -c -std=c++0x -Wall -Werror -fpic -Wno-return-type-c-linkage

SRC = $(wildcard *.cpp)
OBJ = $(SRC:.cpp=.o)

.PHONY: all clean

all: module.o

module.o: $(OBJ)
	$(LD) -r $(OBJ) -o module.o

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

clean:
	-rm -f $(OBJ)
	-rm -f module.o

