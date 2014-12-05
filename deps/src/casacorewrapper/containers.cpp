#include "containers.h"
using namespace casa;

RecordDesc* createRecordDesc() {return new RecordDesc();}
void deleteRecordDesc(RecordDesc* recorddesc) {delete recorddesc;}
void addRecordDescField(RecordDesc* recorddesc, char* field, int type) {
    recorddesc->addField(field,static_cast<DataType>(type));
}

Record* createRecord(RecordDesc* recorddesc) {
    return new Record(RecordDesc(*recorddesc),RecordInterface::Variable);
}
void deleteRecord(Record* record) {delete record;}
unsigned int nfields(Record* record) {return record->nfields();}
int fieldType(Record* record, char* field) {
    uint idx = record->fieldNumber(field);
    return record->type(idx);
}

void putRecordField_float(Record* record, char* field, float value) {
    record->define(field,value);
}
void putRecordField_double(Record* record, char* field, double value) {
    record->define(field,value);
}
void putRecordField_string(Record* record, char* field, char* value) {
    record->define(field,value);
}
void putRecordField_record(Record* record, char* field, Record* value) {
    record->defineRecord(field,Record(*value));
}

float getRecordField_float(Record* record, char* field) {
    return record->asFloat(field);
}
double getRecordField_double(Record* record, char* field) {
    return record->asDouble(field);
}
char const* getRecordField_string(Record* record, char* field) {
    return record->asString(field).c_str();
}
Record* getRecordField_record(Record* record, char* field) {
    return new Record(record->asRecord(field));
}

float read_float(ValueHolder& value) {return value.asFloat();}
double read_double(ValueHolder& value) {return value.asDouble();}
char const* read_string(ValueHolder& value) {
    String str = value.asString();
    return str.c_str();
}

