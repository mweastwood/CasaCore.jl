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

abstract Measure

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

include("epoch.jl")
include("direction.jl")
include("position.jl")

function set!(frame::ReferenceFrame,epoch::Epoch)
    ccall(("setEpoch",libcasacorewrapper), Void,
          (Ptr{Void},Ptr{Void}), pointer(frame), pointer(epoch))
end

function set!(frame::ReferenceFrame,position::Position)
    ccall(("setPosition",libcasacorewrapper), Void,
          (Ptr{Void},Ptr{Void}), pointer(frame), pointer(position))
end

function set!(frame::ReferenceFrame,direction::Direction)
    ccall(("setDirection",libcasacorewrapper), Void,
          (Ptr{Void},Ptr{Void}), pointer(frame), pointer(direction))
end

################################################################################
# Miscellaneous Functions

function observatory(name::ASCIIString)
    position = Position()
    status = ccall(("observatory",libcasacorewrapper), Bool,
                   (Ptr{Void},Ptr{Cchar}), pointer(position), pointer(name))
    !status && error("Unknown observatory.")
    position
end

