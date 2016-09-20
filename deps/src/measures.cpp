// Copyright (c) 2015, 2016 Michael Eastwood
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
#include <measures/Measures.h>
#include <measures/Measures/MeasFrame.h>
#include <measures/Measures/MeasTable.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MCEpoch.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MCDirection.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MCPosition.h>
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/MCBaseline.h>

using namespace std;
using namespace casa;

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

extern "C" {
    MeasFrame* newReferenceFrame() {return new MeasFrame();}
    void deleteReferenceFrame(MeasFrame* frame) {delete frame;}

    MEpoch* newEpoch(Epoch epoch) {
        return new MEpoch(Quantity(epoch.time, "s"), MEpoch::Ref(epoch.sys));
    }

    MDirection* newDirection(Direction direction) {
        return new MDirection(MVDirection(direction.x, direction.y, direction.z),
                              MDirection::Ref(direction.sys));
    }
    MDirection* newDirection_longlat(int sys, double longitude, double latitude) {
        return new MDirection(Quantity(longitude, "rad"),
                              Quantity( latitude, "rad"), MDirection::Ref(sys));
    }

    MPosition* newPosition(Position position) {
        return new MPosition(MVPosition(position.x, position.y, position.z),
                             MPosition::Ref(position.sys));
    }
    MPosition* newPosition_elevationlonglat(int sys, double elevation, double longitude, double latitude) {
        return new MPosition(Quantity(elevation, "m"),
                             Quantity(longitude, "rad"),
                             Quantity( latitude, "rad"), MPosition::Ref(sys));
    }

    MBaseline* newBaseline(Baseline baseline) {
        return new MBaseline(MVBaseline(baseline.x, baseline.y, baseline.z),
                             MBaseline::Ref(baseline.sys));
    }

    void     deleteEpoch(    MEpoch*     mepoch) {delete mepoch;}
    void deleteDirection(MDirection* mdirection) {delete mdirection;}
    void  deletePosition( MPosition*  mposition) {delete mposition;}
    void  deleteBaseline( MBaseline*  mbaseline) {delete mbaseline;}

    Epoch getEpoch(MEpoch* mepoch) {
        Epoch epoch;
        epoch.sys  = mepoch->getRef().getType();
        epoch.time = mepoch->get("s").getValue();
        return epoch;
    }

    Direction getDirection(MDirection* mdirection) {
        Vector<Double> vec = mdirection->getValue().getVector();
        Direction direction;
        direction.sys = mdirection->getRef().getType();
        direction.x = vec(0);
        direction.y = vec(1);
        direction.z = vec(2);
        return direction;
    }

    Position getPosition(MPosition* mposition) {
        Vector<Double> vec = mposition->getValue().getVector();
        Position position;
        position.sys = mposition->getRef().getType();
        position.x = vec(0);
        position.y = vec(1);
        position.z = vec(2);
        return position;
    }

    Baseline getBaseline(MBaseline* mbaseline) {
        Vector<Double> vec = mbaseline->getValue().getVector();
        Baseline baseline;
        baseline.sys = mbaseline->getRef().getType();
        baseline.x = vec(0);
        baseline.y = vec(1);
        baseline.z = vec(2);
        return baseline;
    }

    void setEpoch    (MeasFrame* frame, MEpoch*     mepoch)     {frame->set(*mepoch);}
    void setDirection(MeasFrame* frame, MDirection* mdirection) {frame->set(*mdirection);}
    void setPosition (MeasFrame* frame, MPosition*  mposition)  {frame->set(*mposition);}

    MEpoch* convertEpoch(MeasFrame* frame, MEpoch* mepoch, int newsys) {
        return new MEpoch(MEpoch::Convert(*mepoch,MEpoch::Ref(newsys,*frame))());
    }
    MDirection* convertDirection(MeasFrame* frame, MDirection* mdirection, int newsys) {
        return new MDirection(MDirection::Convert(*mdirection,MDirection::Ref(newsys,*frame))());
    }
    MPosition* convertPosition(MeasFrame* frame, MPosition* mposition, int newsys) {
        return new MPosition(MPosition::Convert(*mposition,MPosition::Ref(newsys,*frame))());
    }
    MBaseline* convertBaseline(MeasFrame* frame, MBaseline* mbaseline, int newsys) {
        return new MBaseline(MBaseline::Convert(*mbaseline,MBaseline::Ref(newsys,*frame))());
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

