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
#include <measures/Measures/MeasFrame.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MCEpoch.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MCDirection.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MCPosition.h>
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/MCBaseline.h>

using namespace casa;

extern "C" {
    MeasFrame* newFrame() {return new MeasFrame();}
    void deleteFrame(MeasFrame* frame) {delete frame;}

    void setEpoch    (MeasFrame* frame, MEpoch*     epoch)     {frame->set(*epoch);}
    void setDirection(MeasFrame* frame, MDirection* direction) {frame->set(*direction);}
    void setPosition (MeasFrame* frame, MPosition*  position)  {frame->set(*position);}

    MDirection* convertDirection(MDirection* direction, int newref, MeasFrame* frame) {
        return new MDirection(MDirection::Convert(*direction,MDirection::Ref(newref,*frame))());
    }

    MPosition* convertPosition(MPosition* position, int newref, MeasFrame* frame) {
        return new MPosition(MPosition::Convert(*position,MPosition::Ref(newref,*frame))());
    }

    MBaseline* convertBaseline(MBaseline* baseline, int newref, MeasFrame* frame) {
        return new MBaseline(MBaseline::Convert(*baseline,MBaseline::Ref(newref,*frame))());
    }

    MEpoch::Convert* newEpochConverter(int from, int to, MeasFrame* frame) {
        return new MEpoch::Convert(MEpoch::Ref(from), MEpoch::Ref(to,*frame));
    }
    MEpoch* runEpochConverter(MEpoch::Convert* converter, MEpoch* epoch) {
        return new MEpoch((*converter)(epoch));
    }
    void deleteEpochConverter(MEpoch::Convert* converter) {
        delete converter;
    }

    MDirection::Convert* newDirectionConverter(int from, int to, MeasFrame* frame) {
        return new MDirection::Convert(MDirection::Ref(from), MDirection::Ref(to,*frame));
    }
    MDirection* runDirectionConverter(MDirection::Convert* converter, MDirection* epoch) {
        return new MDirection((*converter)(epoch));
    }
    void deleteDirectionConverter(MDirection::Convert* converter) {
        delete converter;
    }

    MPosition::Convert* newPositionConverter(int from, int to, MeasFrame* frame) {
        return new MPosition::Convert(MPosition::Ref(from), MPosition::Ref(to,*frame));
    }
    MPosition* runPositionConverter(MPosition::Convert* converter, MPosition* epoch) {
        return new MPosition((*converter)(epoch));
    }
    void deletePositionConverter(MPosition::Convert* converter) {
        delete converter;
    }

    MBaseline::Convert* newBaselineConverter(int from, int to, MeasFrame* frame) {
        return new MBaseline::Convert(MBaseline::Ref(from), MBaseline::Ref(to,*frame));
    }
    MBaseline* runBaselineConverter(MBaseline::Convert* converter, MBaseline* epoch) {
        return new MBaseline((*converter)(epoch));
    }
    void deleteBaselineConverter(MBaseline::Convert* converter) {
        delete converter;
    }

}

