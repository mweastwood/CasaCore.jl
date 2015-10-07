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
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>

using namespace casa;

extern "C" {
    MeasFrame* newFrame() {return new MeasFrame();}
    void deleteFrame(MeasFrame* frame) {delete frame;}

    void setEpoch    (MeasFrame* frame, MEpoch*     epoch)     {frame->set(*epoch);}
    void setDirection(MeasFrame* frame, MDirection* direction) {frame->set(*direction);}
    void setPosition (MeasFrame* frame, MPosition*  position)  {frame->set(*position);}
}

