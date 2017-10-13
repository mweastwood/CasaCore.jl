CXX = g++
LDLIBS = -lcasa_tables -lcasa_measures
LDFLAGS = -Wl,-rpath,\$$ORIGIN

MODULES = tables
OBJ = $(addsuffix /module.o, $(MODULES))

.PHONY: all clean $(MODULES)

all: libcasacorewrapper.so

libcasacorewrapper.so: $(MODULES)
	$(CXX) -shared $(LDFLAGS) -o libcasacorewrapper.so $(OBJ) $(LDLIBS)

$(MODULES):
	$(MAKE) -C $@

clean:
	-rm -f libcasacorewrapper.so

