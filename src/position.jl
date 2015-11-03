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
    eval(current_module(),:(Measures.Types_of_Positions.$(symbol(sys))))
end

@measure :Position 3

@doc doc"""
    type Position{sys} <: Measure

This type represents a location on the surface of the Earth
(ie. a position). Tye type parameter `sys` defines the
coordinate system.

    Position(sys, length::Quantity, longitude::Quantity, latitude::Quantity)

Instantiate an epoch from the given coordinate system, length, longitude,
and latitude. Depending on the coordinate system, the length can either
represent the elevation relative to sea level or the distance from the
center of the Earth.

    Position(sys, x::Float64, y::Float64, z::Float64)

Construct a position from the Cartesian vector $(x,y,z)$ where each
coordinate has units of meters.
""" Position

@add_vector_like_methods :Position

function show(io::IO, position::Position)
    L    = length(position,"m")
    long = longitude(position,"deg")
    lat  =  latitude(position,"deg")
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
    length    = Quantity(Unit("m"))
    longitude = Quantity(Unit("rad"))
    latitude  = Quantity(Unit("rad"))
    sys       = Ref{Cint}(0)
    status = ccall(("observatory",libcasacorewrapper), Bool,
                   (Ptr{Void},Ptr{Void},Ptr{Void},Ref{Cint},Ptr{Cchar}),
                   pointer(length), pointer(longitude), pointer(latitude), sys, pointer(name))
    !status && error("Unknown observatory.")
    Position(Types_of_Positions.System(sys[]), length, longitude, latitude)
end

