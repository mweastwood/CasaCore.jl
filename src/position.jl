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

module Types_of_Positions
    @enum(System, ITRF, WGS84)
end

macro pos_str(sys)
    :(Types_of_Positions.$(symbol(sys))) |> eval
end

"""
    type Position{sys} <: Measure

This type represents a location on the surface of the Earth
(ie. a position). Tye type parameter `sys` defines the
coordinate system.
"""
type Position{sys} <: Measure
    ptr::Ptr{Void} # pointer to a casa::MPosition instance
end

"""
    Position(sys, length::Quantity, longitude::Quantity, latitude::Quantity)

Instantiate an epoch from the given coordinate system, length, longitude,
and latitude. Depending on the coordinate system, the length can either
represent the elevation relative to sea level or the distance from the
center of the Earth.
"""
function Position(sys::Types_of_Positions.System,
                  length::Quantity, longitude::Quantity, latitude::Quantity)
    position = ccall(("newPosition",libcasacorewrapper), Ptr{Void},
                     (Ptr{Void},Ptr{Void},Ptr{Void},Cint),
                     pointer(length), pointer(longitude), pointer(latitude), sys) |> Position{sys}
    finalizer(position,delete)
    position
end

function from_xyz_in_meters(sys::Types_of_Positions.System,
                            x::Float64,y::Float64,z::Float64)
    position = ccall(("newPositionXYZ",libcasacorewrapper), Ptr{Void},
                     (Cdouble,Cdouble,Cdouble,Cint), x, y, z, sys) |> Position{sys}
    finalizer(position,delete)
    position
end

function delete(position::Position)
    ccall(("deletePosition",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(position))
end

pointer(position::Position) = position.ptr
coordinate_system{sys}(::Position{sys}) = sys

function length(position::Position, unit::Unit = Unit("m"))
    ccall(("getPositionLength",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(position), pointer(unit))
end

function longitude(position::Position, unit::Unit = Unit("rad"))
    ccall(("getPositionLongitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(position), pointer(unit))
end

function latitude(position::Position, unit::Unit = Unit("rad"))
    ccall(("getPositionLatitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(position), pointer(unit))
end

function xyz_in_meters(position::Position)
    x = Ref{Cdouble}(0)
    y = Ref{Cdouble}(0)
    z = Ref{Cdouble}(0)
    ccall(("getPositionXYZ",libcasacorewrapper), Void,
          (Ptr{Void},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble}),
          pointer(position), x, y, z)
    x[],y[],z[]
end

function show(io::IO, position::Position)
    L    = length(position,Quanta.Meter)
    long = longitude(position,Unit("deg"))
    lat  =  latitude(position,Unit("deg"))
    print(io,"(",L," m, ",long," deg, ",lat," deg)")
end

function set!(frame::ReferenceFrame,position::Position)
    ccall(("setPosition",libcasacorewrapper), Void,
          (Ptr{Void},Ptr{Void}), pointer(frame), pointer(position))
end

"""
    measure(frame::ReferenceFrame, position::Position, newsys)

Convert the given position to the new coordinate system specified
by `newsys`. The reference frame must have enough information
to attached to it with `set!` for the conversion to be made
from the old coordinate system to the new.
"""
function measure(frame::ReferenceFrame,
                 position::Position,
                 newsys::Types_of_Positions.System)
    newposition = ccall(("convertPosition",libcasacorewrapper), Ptr{Void},
                        (Ptr{Void},Cint,Ptr{Void}),
                        pointer(position), newsys, pointer(frame)) |> Position{newsys}
    finalizer(newposition,delete)
    newposition
end

"""
    observatory(name::ASCIIString)

Get the position of an observatory from its name.

For example `observatory("OVRO_MMA")` gets the position of the
old Millimeter Array at the Owens Valley Radio Observatory.
"""
function observatory(name::ASCIIString)
    position = Position(pos"ITRF",
                        Quantity(0.0,Unit("m")),
                        Quantity(0.0,Unit("rad")),
                        Quantity(0.0,Unit("rad")))
    status = ccall(("observatory",libcasacorewrapper), Bool,
                   (Ptr{Void},Ptr{Cchar}), pointer(position), pointer(name))
    !status && error("Unknown observatory.")
    position
end

