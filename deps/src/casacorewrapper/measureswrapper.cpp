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

#include <measures/Measures/MeasuresProxy.h>

using namespace casa;

extern "C" {
    MeasuresProxy* newMeasures() {return new MeasuresProxy;}
    void deleteMeasures(MeasuresProxy* me) {delete me;}

    void doframe(MeasuresProxy* me, Record* record) {me->doframe(Record(*record));}
    Record* measure(MeasuresProxy* me, Record* record, char* str) {
        return new Record(me->measure(Record(*record),str,Record()));
    }

    Record* source(MeasuresProxy* me, char* name) {
        return new Record(me->source(name));
    }

    Record* observatory(MeasuresProxy* me, char* name) {
        return new Record(me->observatory(name));
    }
}

