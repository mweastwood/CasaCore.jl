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

module Directions
    @enum(System,
          J2000, JMEAN, JTRUE, APP, B1950, B1950_VLA, BMEAN, BTRUE,
          GALACTIC, HADEC, AZEL, AZELSW, AZELGEO, AZELSWGEO, JNAT,
          ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF,
          MERCURY=32, VENUS, MARS, JUPITER, SATURN, URANUS, NEPTUNE,
          PLUTO, SUN, MOON)
end

macro dir_str(sys)
    eval(current_module(),:(Measures.Directions.$(symbol(sys))))
end

@measure :Direction 2

@doc doc"""
    type Direction{sys} <: Measure

This type represents a location on the sky (ie. a direction). The type
parameter `sys` defines the coordinate system.

    Direction(sys, longitude::Quantity, latitude::Quantity)

Instantiate a direction from the given coordinate system, longitude,
and latitude.

    Direction(sys, x::Float64, y::Float64, z::Float64)

Construct a direction from the Cartesian vector $(x,y,z)$ where each
coordinate has units of meters.

    Direction(sys)

Instantiate a direction with the given coordinate system. The longitude
and latitude are set to zero.

This constructor should be used for solar system objects.

** Examples:**

    Direction(dir"SUN")     # the direction towards the Sun
    Direction(dir"JUPITER") # the direction towards Jupiter
""" Direction

function Direction(sys::Directions.System)
    Direction(sys,Quantity(Unit("rad")),Quantity(Unit("rad")))
end

@add_vector_like_methods :Direction

function show(io::IO, direction::Direction)
    long = longitude(direction,"deg")
    lat  =  latitude(direction,"deg")
    print(io,"(",long," deg, ",lat," deg)")
end

