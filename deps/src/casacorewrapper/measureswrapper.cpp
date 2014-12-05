#include <measures/Measures/MeasuresProxy.h>

using namespace casa;

extern "C" {
    MeasuresProxy* newMeasures() {return new MeasuresProxy;}
    void deleteMeasures(MeasuresProxy* me) {delete me;}

    void doframe(MeasuresProxy* me, Record* record) {me->doframe(Record(*record));}
    Record* measure(MeasuresProxy* me, Record* record, char* str) {
        return new Record(me->measure(Record(*record),str,Record()));
    }

    Record* observatory(MeasuresProxy* me, char* name) {
        return new Record(me->observatory(String(name)));
    }
}

