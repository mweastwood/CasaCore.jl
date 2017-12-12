# Copyright (c) 2015-2017 Michael Eastwood
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
          ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF, TOPO, ICRS,
          MERCURY=32, VENUS, MARS, JUPITER, SATURN, URANUS, NEPTUNE,
          PLUTO, SUN, MOON)
end

macro dir_str(sys)
    eval(current_module(),:(Measures.Directions.$(Symbol(sys))))
end

"""
    Direction <: Measure

This type represents a location on the sky.
"""
struct Direction <: Measure
    sys :: Directions.System
    x :: Float64
    y :: Float64
    z :: Float64
    function Direction(sys, x, y, z)
        magnitude = hypot(x, y, z)
        new(sys, x/magnitude, y/magnitude, z/magnitude)
    end
end

struct UnnormalizedDirection <: Measure
    sys :: Directions.System
    x :: Float64
    y :: Float64
    z :: Float64
end

function Base.convert(::Type{Direction}, direction::UnnormalizedDirection)
    Direction(direction.sys, direction.x, direction.y, direction.z)
end

function Base.convert(::Type{UnnormalizedDirection}, direction::Direction)
    UnnormalizedDirection(direction.sys, direction.x, direction.y, direction.z)
end


units(::Direction) = 1 # dimensionless
units(::Type{Direction}) = 1
units(::UnnormalizedDirection) = 1 # dimensionless
units(::Type{UnnormalizedDirection}) = 1


"""
    Direction(sys, longitude, latitude)
    Direction(sys)

Instantiate a direction in the given coordinate system (`sys`).

The longitude and latitude may either be a sexagesimally formatted string, or an angle where the
units (degrees or radians) are specified by using the Unitful package. If the longitude and latitude
coordinates are not provided, they are assumed to be zero.

**Coordinate Systems:**

The coordinate system is selected using the string macro `dir"..."` where the `...` is replaced with
one of the coordinate systems listed below.

* `J2000` - mean equator and equinox at J2000.0 (FK5)
* `JMEAN` - mean equator and equinox at frame epoch
* `JTRUE` - true equator and equinox at frame epoch
* `APP` - apparent geocentric position
* `B1950` - mean epoch and ecliptic at B1950.0
* `B1950_VLA` - mean epoch (1979.9) and ecliptic at B1950.0
* `BMEAN` - mean equator and equinox at frame epoch
* `BTRUE` - true equator and equinox at frame epoch
* `GALACTIC` - galactic coordinates
* `HADEC` - topocentric hour angle and declination
* `AZEL` - topocentric azimuth and elevation (N through E)
* `AZELSW` - topocentric azimuth and elevation (S through W)
* `AZELGEO` - geodetic azimuth and elevation (N through E)
* `AZELSWGEO` - geodetic azimuth and elevation (S through W)
* `JNAT` - geocentric natural frame
* `ECLIPTIC` - ecliptic for J2000 equator and equinox
* `MECLIPTIC` - ecliptic for mean equator of date
* `TECLIPTIC` - ecliptic for true equator of date
* `SUPERGAL` - supergalactic coordinates
* `ITRF` - coordinates with respect to the ITRF Earth frame
* `TOPO` - apparent topocentric position
* `ICRS` - international celestial reference system
* `MERCURY`
* `VENUS`
* `MARS`
* `JUPITER`
* `SATURN`
* `URANUS`
* `NEPTUNE`
* `PLUTO`
* `SUN`
* `MOON`

**Examples:**

``` julia
using Unitful: °, rad
Direction(dir"AZEL", 0°, 90°) # topocentric zenith
Direction(dir"ITRF", 0rad, 1rad)
Direction(dir"J2000", "12h00m", "43d21m")
Direction(dir"SUN")     # the direction towards the Sun
Direction(dir"JUPITER") # the direction towards Jupiter
```
"""
function Direction(sys::Directions.System, longitude::Angle, latitude::Angle)
    long = uconvert(u"rad", longitude) |> ustrip
    lat  = uconvert(u"rad",  latitude) |> ustrip
    x = cos(lat)*cos(long)
    y = cos(lat)*sin(long)
    z = sin(lat)
    Direction(sys, x, y, z)
end

function Direction(sys::Directions.System, longitude::AbstractString, latitude::AbstractString)
    Direction(sys, sexagesimal(longitude)*u"rad", sexagesimal(latitude)*u"rad")
end

Direction(sys::Directions.System) = Direction(sys, 1.0, 0.0, 0.0)

function Base.show(io::IO, direction::Direction)
    long_str = direction |> longitude |> sexagesimal
    lat_str  = direction |>  latitude |> sexagesimal
    print(io, long_str, ", ", lat_str)
end

