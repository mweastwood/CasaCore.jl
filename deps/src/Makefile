CXX = g++
CXXFLAGS = -c -std=c++0x -Wall -Werror -fpic -Wno-return-type-c-linkage
LDLIBS = -lcasa_tables -lcasa_measures
LDFLAGS = -Wl,-rpath,\$$ORIGIN

TABLES_SRC=tables/util.cpp tables/tables.cpp tables/rows.cpp tables/columns.cpp
TABLES_OBJ=$(TABLES_SRC:.cpp=.o) 

LIBRARIES=libcasacorewrapper_tables.so

all: libcasacorewrapper.so

$(TABLES_OBJ): %.o: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

libcasacorewrapper_tables.so: $(TABLES_OBJ)
	$(CXX) -shared $(LDFLAGS) -o libcasacorewrapper_tables.so $(TABLES_OBJ) $(LDLIBS)

libcasacorewrapper.so: libcasacorewrapper_tables.so
	$(CXX) -shared $(LDFLAGS) -o libcasacorewrapper.so $(LIBRARIES) $(LDLIBS)

clean:
	-rm -f $(TABLES_OBJ)

distclean: clean
	-rm -f $(LIBRARIES)
	-rm libcasacorewrapper.so

