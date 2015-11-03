# Copyright (c) 2015 Michael Eastwood
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

type ReferenceFrame
    ptr::Ptr{Void}
end

function ReferenceFrame()
    frame = ccall(("newFrame",libcasacorewrapper), Ptr{Void}, ()) |> ReferenceFrame
    finalizer(frame,delete)
    frame
end

function delete(frame::ReferenceFrame)
    ccall(("deleteFrame",libcasacorewrapper), Void, (Ptr{Void},), pointer(frame))
end

pointer(frame::ReferenceFrame) = frame.ptr

for T in (:Epoch, :Direction, :Position)
    cfunc = string("set",T)
    @eval function set!(frame::ReferenceFrame, measure::$T)
        ccall(($cfunc,libcasacorewrapper), Void, (Ptr{Void},Ptr{Void}),
              pointer(frame), pointer(measure))
    end
end

@doc """
    set!(frame::ReferenceFrame, measure)

Attach the given measure to the frame of reference.

This is needed for some coordinate conversions that require extra information.
For example, converting J2000 coordinates to AZEL (azimuth and elevation)
requires knowing the position and time of the observer.
""" set!

for T in (:Epoch, :Direction, :Position, :Baseline)
    Ts = symbol(T,"s")

    cfunc = string("convert",T)
    @eval function measure(frame::ReferenceFrame, input::$T, newsys::$Ts.System)
        output = ccall(($cfunc,libcasacorewrapper), Ptr{Void}, (Ptr{Void},Cint,Ptr{Void}),
                       pointer(input), newsys, pointer(frame)) |> $T{newsys}
        finalizer(output, delete)
        output
    end
end

@doc """
    measure(frame::ReferenceFrame, input::Measure, newsys)

Convert the given measure to the new coordinate system specified
by `newsys`. The reference frame must have enough information
to attached to it with `set!` for the conversion to be made
from the old coordinate system to the new.

**Example:**

    position = observatory("VLA")
    measure(ReferenceFrame(), position, pos"WGS84")
""" measure

