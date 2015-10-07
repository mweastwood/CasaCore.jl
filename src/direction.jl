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

module Types_of_Directions
    @enum(System,
          J2000, JMEAN, JTRUE, APP, B1950, B1950_VLA, BMEAN, BTRUE,
          GALACTIC, HADEC, AZEL, AZELSW, AZELGEO, AZELSWGEO, JNAT,
          ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF,
          MERCURY=32, VENUS, MARS, JUPITER, SATURN, URANUS, NEPTUNE,
          PLUTO, SUN, MOON)
end

macro dir_str(sys)
    :(Types_of_Directions.$(symbol(sys))) |> eval
end

"""
    type Direction{sys} <: Measure

This type represents a location on the sky (ie. a direction). The type
parameter `sys` defines the coordinate system.
"""
type Direction{sys} <: Measure
    ptr::Ptr{Void}
end

"""
    Direction(sys, longitude::Quantity, latitude::Quantity)

Instantiate a direction from the given coordinate system, longitude,
and latitude.
"""
function Direction(sys::Types_of_Directions.System,
                   longitude::Quantity, latitude::Quantity)
    direction = ccall(("newDirection",libcasacorewrapper), Ptr{Void},
                      (Ptr{Void},Ptr{Void},Cint),
                      pointer(longitude), pointer(latitude), sys) |> Direction{sys}
    finalizer(direction,delete)
    direction
end

"""
    Direction(sys)

Instantiate a direction with the given coordinate system. The longitude
and latitude are set to zero.

This constructor should be used for solar system objects.

** Examples:**

    Direction(dir"SUN")     # the direction towards the Sun
    Direction(dir"JUPITER") # the direction towards Jupiter
"""
function Direction(sys::Types_of_Directions.System)
    Direction(sys,Quantity(Unit("rad")),Quantity(Unit("rad")))
end

function from_xyz_in_meters(sys::Types_of_Directions.System,
                            x::Float64,y::Float64,z::Float64)
    direction = ccall(("newDirectionXYZ",libcasacorewrapper), Ptr{Void},
                     (Cdouble,Cdouble,Cdouble,Cint), x, y, z, sys) |> Direction{sys}
    finalizer(direction,delete)
    direction
end

function delete(direction::Direction)
    ccall(("deleteDirection",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(direction))
end

pointer(direction::Direction) = direction.ptr
coordinate_system{sys}(::Direction{sys}) = sys

function longitude(direction::Direction, unit::Unit = Unit("rad"))
    ccall(("getDirectionLongitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(direction), pointer(unit))
end

function latitude(direction::Direction, unit::Unit = Unit("rad"))
    ccall(("getDirectionLatitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(direction), pointer(unit))
end

function xyz_in_meters(direction::Direction)
    x = Ref{Cdouble}(0)
    y = Ref{Cdouble}(0)
    z = Ref{Cdouble}(0)
    ccall(("getDirectionXYZ",libcasacorewrapper), Void,
          (Ptr{Void},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble}),
          pointer(direction), x, y, z)
    x[],y[],z[]
end

function show(io::IO, direction::Direction)
    long = longitude(direction,Unit("deg"))
    lat  =  latitude(direction,Unit("deg"))
    print(io,"(",long," deg, ",lat," deg)")
end

function set!(frame::ReferenceFrame,direction::Direction)
    ccall(("setDirection",libcasacorewrapper), Void,
          (Ptr{Void},Ptr{Void}), pointer(frame), pointer(direction))
end

"""
    measure(frame::ReferenceFrame, direction::Direction, newsys)

Convert the given direction to the new coordinate system specified
by `newsys`. The reference frame must have enough information
to attached to it with `set!` for the conversion to be made
from the old coordinate system to the new.
"""
function measure(frame::ReferenceFrame,
                 direction::Direction,
                 newsys::Types_of_Directions.System)
    newdirection = ccall(("convertDirection",libcasacorewrapper), Ptr{Void},
                         (Ptr{Void},Cint,Ptr{Void}),
                         pointer(direction), newsys, pointer(frame)) |> Direction{newsys}
    finalizer(newdirection,delete)
    newdirection
end

