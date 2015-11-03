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

    cfunc_new = string("new",T,"Converter")
    @eval function new_converter(::Type{$T}, from, to, frame::ReferenceFrame)
        ccall(($cfunc_new,libcasacorewrapper), Ptr{Void}, (Cint,Cint,Ptr{Void}),
              from, to, pointer(frame))
    end

    cfunc_run = string("run",T,"Converter")
    @eval function run_converter(converter, input::$T)
        ccall(($cfunc_run,libcasacorewrapper), Ptr{Void}, (Ptr{Void},Ptr{Void}),
              converter, pointer(input))
    end

    cfunc_del = string("delete",T,"Converter")
    @eval function delete_converter(::Type{$T}, converter)
        ccall(($cfunc_del,libcasacorewrapper), Void, (Ptr{Void},), converter)
    end

    @eval function measure{from}(frame::ReferenceFrame, input::$T{from}, to::$Ts.System)
        converter = new_converter($T, from, to, frame)
        output    = run_converter(converter, input) |> $T{to}
        delete_converter($T, converter)
        finalizer(output, delete)
        output
    end

    @eval function measure{from}(frame::ReferenceFrame, input::Vector{$T{from}}, to::$Ts.System)
        converter = new_converter($T, from, to, frame)
        output = Array{$T{to}}(length(input))
        for i = 1:length(input)
            output[i] = run_converter(converter, input[i]) |> $T{to}
            finalizer(output[i], delete)
        end
        delete_converter($T, converter)
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

