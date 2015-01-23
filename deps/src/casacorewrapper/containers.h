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

#ifndef CONTAINERS_H
#define CONTAINERS_H

#include <casa/Containers/Record.h>
#include <casa/Containers/ValueHolder.h>

extern "C" {
    casa::RecordDesc* createRecordDesc();
    void   deleteRecordDesc(casa::RecordDesc* recorddesc);
    void addRecordDescField(casa::RecordDesc* recorddesc, char* field, int type);

    casa::Record* createRecord(casa::RecordDesc* recorddesc);
    void    deleteRecord(casa::Record* record);
    unsigned int nfields(casa::Record* record);
    int        fieldType(casa::Record* record, char* field);

    void putRecordField_float (casa::Record* record, char* field,         float value);
    void putRecordField_double(casa::Record* record, char* field,        double value);
    void putRecordField_string(casa::Record* record, char* field,         char* value);
    void putRecordField_record(casa::Record* record, char* field, casa::Record* value);

    float         getRecordField_float (casa::Record* record, char* field);
    double        getRecordField_double(casa::Record* record, char* field);
    char const*   getRecordField_string(casa::Record* record, char* field);
    casa::Record* getRecordField_record(casa::Record* record, char* field);

    float  read_float (casa::ValueHolder& value);
    double read_double(casa::ValueHolder& value);
    char const* read_string(casa::ValueHolder& value);
}

#endif

