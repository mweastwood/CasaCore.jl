// Copyright (c) 2015 Michael Eastwood
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include "containers.h"
using namespace casa;

// Record

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

