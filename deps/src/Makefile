CXX = g++
LDLIBS = -lcasa_casa -lcasa_tables -lcasa_measures -lcasa_ms
LDFLAGS = -Wl,-rpath,\$$ORIGIN -Wl,--no-undefined

MODULES = tables measures measurement-sets
OBJ = $(addsuffix /module.o, $(MODULES))

.PHONY: all clean $(MODULES)

all: libcasacorewrapper.so

libcasacorewrapper.so: $(MODULES)
	$(CXX) -shared $(LDFLAGS) -o libcasacorewrapper.so $(OBJ) $(LDLIBS)

$(MODULES):
	$(MAKE) -C $@

clean:
	-rm -f libcasacorewrapper.so

