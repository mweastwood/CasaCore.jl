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

#include <measures/Measures.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MeasTable.h>

using namespace casa;

extern "C" {
    MPosition* newPosition(int ref, Quantity* length, Quantity* longitude, Quantity* latitude) {
        return new MPosition(*length, *longitude, *latitude, MPosition::Ref(ref));
    }

    MPosition* newPositionXYZ(int ref, double x, double y, double z) {
        return new MPosition(MVPosition(x,y,z), MPosition::Ref(ref));
    }

    void deletePosition(MPosition* position) {
        delete position;
    }

    double getPositionLength(MPosition* position, Unit* unit) {
        return position->getValue().getLength(*unit).getValue();
    }

    double getPositionLongitude(MPosition* position, Unit* unit) {
        return position->getValue().getLong(*unit).getValue();
    }

    double getPositionLatitude(MPosition* position, Unit* unit) {
        return position->getValue().getLat(*unit).getValue();
    }

    void getPositionXYZ(MPosition* position, double* x, double* y, double* z) {
        Vector<Double> vec = position->getValue().getVector();
        *x = vec(0);
        *y = vec(1);
        *z = vec(2);
    }

    bool observatory(Quantity* length, Quantity* longitude, Quantity* latitude, int* ref, char* name) {
        MPosition position(*length, *longitude, *latitude, MPosition::Ref(*ref));
        bool found = MeasTable::Observatory(position, name);
        *length = position.getValue().getLength(length->getUnit());
        *longitude = position.getValue().getLong(longitude->getUnit());
        *latitude  = position.getValue().getLat(latitude->getUnit());
        *ref = position.getRef().getType();
        return found;
    }
}

