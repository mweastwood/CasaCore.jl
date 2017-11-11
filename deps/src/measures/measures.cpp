// Copyright (c) 2015-2017 Michael Eastwood
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

#include <iostream>
#include <casacore/measures/Measures.h>
#include <casacore/measures/Measures/MeasFrame.h>
#include <casacore/measures/Measures/MeasTable.h>
#include <casacore/measures/Measures/MEpoch.h>
#include <casacore/measures/Measures/MCEpoch.h>
#include <casacore/measures/Measures/MDirection.h>
#include <casacore/measures/Measures/MCDirection.h>
#include <casacore/measures/Measures/MPosition.h>
#include <casacore/measures/Measures/MCPosition.h>
#include <casacore/measures/Measures/MBaseline.h>
#include <casacore/measures/Measures/MCBaseline.h>

using namespace std;
using namespace casacore;

// These structs must mirror their corresponding Julia types.

struct Epoch {
    int sys;
    double time; // measured in seconds
};

struct Direction {
    int sys;
    double x; // measured in meters
    double y; // measured in meters
    double z; // measured in meters
};

struct Position {
    int sys;
    double x; // measured in meters
    double y; // measured in meters
    double z; // measured in meters
};

struct Baseline {
    int sys;
    double x; // measured in meters
    double y; // measured in meters
    double z; // measured in meters
};

// In some cases we will want to use Julia's nullable types. These types have an extra bool. If the
// definition of Julia's nullable types ever changes, these definitions will need to be updated.
//
// NOTE: In Julia v0.6 the `isnull` field changed to `hasvalue`.

struct NullableEpoch {
    bool hasvalue;
    Epoch value;
};

struct NullableDirection {
    bool hasvalue;
    Direction value;
};

struct NullablePosition {
    bool hasvalue;
    Position value;
};

struct ReferenceFrame {
    NullableEpoch epoch;
    NullableDirection direction;
    NullablePosition position;
};

// Define conversion routines from the C++ types to the Julia types.

Epoch getEpoch(MEpoch const& mepoch) {
    Epoch epoch;
    epoch.sys  = mepoch.getRef().getType();
    epoch.time = mepoch.get("s").getValue();
    return epoch;
}

Direction getDirection(MDirection const& mdirection) {
    Vector<Double> vec = mdirection.getValue().getVector();
    Direction direction;
    direction.sys = mdirection.getRef().getType();
    direction.x = vec(0);
    direction.y = vec(1);
    direction.z = vec(2);
    return direction;
}

Position getPosition(MPosition const& mposition) {
    Vector<Double> vec = mposition.getValue().getVector();
    Position position;
    position.sys = mposition.getRef().getType();
    position.x = vec(0);
    position.y = vec(1);
    position.z = vec(2);
    return position;
}

Baseline getBaseline(MBaseline const& mbaseline) {
    Vector<Double> vec = mbaseline.getValue().getVector();
    Baseline baseline;
    baseline.sys = mbaseline.getRef().getType();
    baseline.x = vec(0);
    baseline.y = vec(1);
    baseline.z = vec(2);
    return baseline;
}

// Define conversion routines from the Julia types to the C++ types.

MEpoch getMEpoch(Epoch const& epoch) {
    return MEpoch(Quantity(epoch.time, "s"), MEpoch::Ref(epoch.sys));
}

MDirection getMDirection(Direction const& direction) {
    return MDirection(MVDirection(direction.x, direction.y, direction.z),
                      MDirection::Ref(direction.sys));
}

MPosition getMPosition(Position const& position) {
    return MPosition(MVPosition(position.x, position.y, position.z),
                     MPosition::Ref(position.sys));
}

MBaseline getMBaseline(Baseline const& baseline) {
    return MBaseline(MVBaseline(baseline.x, baseline.y, baseline.z),
                     MBaseline::Ref(baseline.sys));
}

MeasFrame getMeasFrame(ReferenceFrame const& frame) {
    MeasFrame mframe = MeasFrame();
    if (frame.epoch.hasvalue) {
        MEpoch mepoch = getMEpoch(frame.epoch.value);
        mframe.set(mepoch);
    }
    if (frame.direction.hasvalue) {
        MDirection mdirection = getMDirection(frame.direction.value);
        mframe.set(mdirection);
    }
    if (frame.position.hasvalue) {
        MPosition mposition = getMPosition(frame.position.value);
        mframe.set(mposition);
    }
    return mframe;
}

extern "C" {
    Epoch convertEpoch(Epoch* input, int newsys) {
        MEpoch input_epoch = getMEpoch(*input);
        MEpoch output_epoch = MEpoch::Convert(input_epoch, MEpoch::Ref(newsys))();
        return getEpoch(output_epoch);
    }

    Direction convertDirection(Direction* input, int newsys, ReferenceFrame* frame) {
        MDirection input_direction = getMDirection(*input);
        MeasFrame mframe = getMeasFrame(*frame);
        MDirection::Ref ref = MDirection::Ref(newsys, mframe);
        MDirection output_direction = MDirection::Convert(input_direction, ref)();
        return getDirection(output_direction);
    }

    Position convertPosition(Position* input, int newsys, ReferenceFrame* frame) {
        MPosition input_position = getMPosition(*input);
        MeasFrame mframe = getMeasFrame(*frame);
        MPosition::Ref ref = MPosition::Ref(newsys, mframe);
        MPosition output_position = MPosition::Convert(input_position, ref)();
        return getPosition(output_position);
    }

    Baseline convertBaseline(Baseline* input, int newsys, ReferenceFrame* frame) {
        MBaseline input_baseline = getMBaseline(*input);
        MeasFrame mframe = getMeasFrame(*frame);
        MBaseline::Ref ref = MBaseline::Ref(newsys, mframe);
        MBaseline output_baseline = MBaseline::Convert(input_baseline, ref)();
        return getBaseline(output_baseline);
    }

    bool observatory(Position* position, char* name) {
        MPosition mposition;
        bool found = MeasTable::Observatory(mposition, name);
        Vector<Double> vec = mposition.getValue().getVector();
        position->sys = mposition.getRef().getType();
        position->x = vec(0);
        position->y = vec(1);
        position->z = vec(2);
        return found;
    }
}

