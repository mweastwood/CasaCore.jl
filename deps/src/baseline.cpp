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
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/MCBaseline.h>

using namespace casa;

extern "C" {
    MBaseline* newBaseline(int ref, Quantity* length, Quantity* longitude, Quantity* latitude) {
        return new MBaseline(MVBaseline(*length, *longitude, *latitude), MBaseline::Ref(ref));
    }

    MBaseline* newBaselineXYZ(int ref, double x, double y, double z) {
        return new MBaseline(MVBaseline(x,y,z), MBaseline::Ref(ref));
    }

    void deleteBaseline(MBaseline* baseline) {
        delete baseline;
    }

    double getBaselineLength(MBaseline* baseline, Unit* unit) {
        return baseline->getValue().getLength(*unit).getValue();
    }

    double getBaselineLongitude(MBaseline* baseline, Unit* unit) {
        return baseline->getValue().getLong(*unit).getValue();
    }

    double getBaselineLatitude(MBaseline* baseline, Unit* unit) {
        return baseline->getValue().getLat(*unit).getValue();
    }

    void getBaselineXYZ(MBaseline* baseline, double* x, double* y, double* z) {
        Vector<Double> vec = baseline->getValue().getVector();
        *x = vec(0);
        *y = vec(1);
        *z = vec(2);
    }

    MBaseline* convertBaseline(MBaseline* baseline, int newref, MeasFrame* frame) {
        return new MBaseline(MBaseline::Convert(*baseline,MBaseline::Ref(newref,*frame))());
    }
}

