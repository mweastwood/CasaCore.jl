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

module Positions
    @enum(System, ITRF, WGS84)
end

macro pos_str(sys)
    eval(current_module(),:(Measures.Positions.$(Symbol(sys))))
end

"""
    Position <: Measure

This type represents a location on the surface of the Earth.
"""
struct Position <: Measure
    sys :: Positions.System
    x :: Float64 # measured in meters
    y :: Float64 # measured in meters
    z :: Float64 # measured in meters
end

units(::Type{Position}) = u"m"

"""
    Position(sys, elevation, longitude, latitude)

Instantiate a position in the given coordinate system (`sys`).

Note that depending on the coordinate system the elevation may be measured relative to the center or
the surface of the Earth.  In both cases the units should be given with the Unitful package.  The
longitude and latitude may either be a sexagesimally formatted string, or an angle where the units
(degrees or radians) are specified by using the Unitful package. If the longitude and latitude
coordinates are not provided, they are assumed to be zero.

**Coordinate Systems:**

The coordinate system is selected using the string macro `pos"..."` where the `...` is replaced with
one of the coordinate systems listed below.

* `ITRF` - the International Terrestrial Reference Frame
* `WGS84` - the World Geodetic System 1984

**Examples:**

``` julia
using Unitful: m, °
Position(pos"WGS84", 5000m, "20d30m00s", "-80d00m00s")
Position(pos"WGS84", 5000m, 20.5°, -80°)
```
"""
function Position(sys::Positions.System, elevation::Unitful.Length, longitude::Angle, latitude::Angle)
    rad  = uconvert(u"m", elevation) |> ustrip
    long = uconvert(u"rad", longitude) |> ustrip
    lat  = uconvert(u"rad",  latitude) |> ustrip
    x = rad*cos(lat)*cos(long)
    y = rad*cos(lat)*sin(long)
    z = rad*sin(lat)
    Position(sys, x, y, z)
end

function Position(sys::Positions.System, elevation::Unitful.Length,
                  longitude::AbstractString, latitude::AbstractString)
    Position(sys, elevation, sexagesimal(longitude)*u"rad", sexagesimal(latitude)*u"rad")
end

function Base.show(io::IO, position::Position)
    rad = norm(position)
    if rad > 1e5*u"m"
        rad_str = @sprintf("%.3f kilometers", rad/1u"km")
    else
        rad_str = @sprintf("%.3f meters", rad/1u"m")
    end
    long_str = position |> longitude |> sexagesimal
    lat_str  = position |>  latitude |> sexagesimal
    print(io, rad_str, ", ", long_str, ", ", lat_str)
end

"""
    observatory(name)

Get the position of an observatory from its name.

**Examples:**

``` julia
observatory("VLA")  # the Very Large Array
observatory("ALMA") # the Atacama Large Millimeter/submillimeter Array
```
"""
function observatory(name::AbstractString)
    position = Position(pos"ITRF", 0.0, 0.0, 0.0) |> Ref{Position}
    status = ccall(("observatory",libcasacorewrapper), Bool,
                   (Ref{Position}, Ptr{Cchar}), position, name)
    !status && err("Unknown observatory.")
    position[]
end

