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
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MCDirection.h>

using namespace casa;

extern "C" {
    MDirection* newDirection(int ref, Quantity* longitude, Quantity* latitude) {
        return new MDirection(*longitude, *latitude, MDirection::Ref(ref));
    }

    MDirection* newDirectionXYZ(int ref, double x, double y, double z) {
        return new MDirection(MVDirection(x,y,z), MDirection::Ref(ref));
    }

    void deleteDirection(MDirection* direction) {
        delete direction;
    }

    double getDirectionLength(MDirection* direction, Unit* unit) {
        return 1.0;
    }

    double getDirectionLongitude(MDirection* direction, Unit* unit) {
        return direction->getValue().getLong(*unit).getValue();
    }

    double getDirectionLatitude(MDirection* direction, Unit* unit) {
        return direction->getValue().getLat(*unit).getValue();
    }

    void getDirectionXYZ(MDirection* direction, double* x, double* y, double* z) {
        Vector<Double> vec = direction->getValue().getVector();
        *x = vec(0);
        *y = vec(1);
        *z = vec(2);
    }

    MDirection* convertDirection(MDirection* direction, int newref, MeasFrame* frame) {
        return new MDirection(MDirection::Convert(*direction,MDirection::Ref(newref,*frame))());
    }
}

