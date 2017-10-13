CXX = g++
CXXFLAGS = -c -std=c++0x -Wall -Werror -fpic -Wno-return-type-c-linkage
LDLIBS = -lcasa_tables -lcasa_measures

TABLES_SRCS=tables/util.cpp tables/tables.cpp tables/rows.cpp tables/columns.cpp
TABLES_OBJS=$(subst .cpp,.o,$(SRCS))

all: libcasacorewrapper_tables.so

%.o: %.cpp util.h
	$(CXX) $(CXXFLAGS) $<

libcasacorewrapper_tables.so: $(OBJS)
	$(CXX) -shared -o libcasacorewrapper_tables.so $(OBJS) $(LDLIBS)

clean:
	-rm -f $(OBJS)

distclean: clean
	-rm -f libcasacorewrapper_tables.so

