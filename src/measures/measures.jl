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

using Unitful
# See https://github.com/ajkeller34/Unitful.jl/issues/38 for a discussion of angle units in the
# Unitful package. We decided that it makes sense for angles to be dimensionless, but Andrew was
# hesitant to commit to this typealias within Unitful.
Angle{T} =  Unitful.DimensionlessQuantity{T}

module Epochs
    @enum(System, LAST, LMST, GMST1, GAST, UT1, UT2, UTC, TAI, TDT, TCG, TDB, TCB)
    const IAT = TAI
    const GMST = GMST1
    const TT = TDT
    const UT = UT1
    const ET = TT
end

module Directions
    @enum(System,
          J2000, JMEAN, JTRUE, APP, B1950, B1950_VLA, BMEAN, BTRUE,
          GALACTIC, HADEC, AZEL, AZELSW, AZELGEO, AZELSWGEO, JNAT,
          ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF, TOPO, ICRS,
          MERCURY=32, VENUS, MARS, JUPITER, SATURN, URANUS, NEPTUNE,
          PLUTO, SUN, MOON)
end

module Positions
    @enum(System, ITRF, WGS84)
end

module Baselines
    @enum(System,
          J2000, JMEAN, JTRUE, APP, B1950, B1950_VLA, BMEAN, BTRUE,
          GALACTIC, HADEC, AZEL, AZELSW, AZELGEO, AZELSWGEO, JNAT,
          ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF, TOPO, ICRS)
    const AZELNE = AZEL
    const AZELNEGEO = AZELGEO
end

abstract type Measure end

"""
    Epoch <: Measure

This type represents an instance in time.
"""
struct Epoch <: Measure
    sys  :: Epochs.System
    time :: Float64 # measured in seconds
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

"""
    Baseline <: Measure

This type represents the location of one antenna relative to another antenna.
"""
struct Baseline <: Measure
    sys :: Baselines.System
    x :: Float64 # measured in meters
    y :: Float64 # measured in meters
    z :: Float64 # measured in meters
end

"""
    Epoch(sys, time)

Instantiate an epoch in the given coordinate system (`sys`).

The `time` should be given as a modified Julian date.  Additionally the Unitful package should be
used to communicate the units of `time`.

For example `time = 57365.5 * u"d"` corresponds to a Julian date of 57365.5 days. However you can
also specify the Julian date in seconds (`u"s"`), or any other unit of time supported by Unitful.

**Coordinate Systems:**

The coordinate system is selected using the string macro `epoch"..."` where the `...` is replaced
with one of the coordinate systems listed below.

* `LAST` - local apparent sidereal time
* `LMST` - local mean sidereal time
* `GMST1` - Greenwich mean sidereal time
* `GAST` - Greenwich apparent sidereal time
* `UT1` - UT0 (raw time from GPS measurements) corrected for polar wandering
* `UT2` - UT1 corrected for variable Earth rotation
* `UTC` - coordinated universal time
* `TAI` - international atomic time
* `TDT` - terrestrial dynamical time
* `TCG` - geocentric coordinate time
* `TDB` - barycentric dynamical time
* `TCB` - barycentric coordinate time

**Examples:**

``` julia
using Unitful: d
Epoch(epoch"UTC",     0.0d) # 1858-11-17T00:00:00
Epoch(epoch"UTC", 57365.5d) # 2015-12-09T12:00:00
```
"""
function Epoch(sys::Epochs.System, time::Unitful.Time)
    seconds = uconvert(u"s", time) |> ustrip
    Epoch(sys, seconds)
end

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

function Base.show(io::IO, epoch::Epoch)
    julian_date = 2400000.5 + epoch.time/(24*60*60)
    print(io, Dates.julian2datetime(julian_date))
end

function Base.show(io::IO, direction::Direction)
    long_str = direction |> longitude |> sexagesimal
    lat_str  = direction |>  latitude |> sexagesimal
    print(io, long_str, ", ", lat_str)
end

function Base.show(io::IO, position::Position)
    rad = norm(position)
    if rad > 1e5
        rad_str = @sprintf("%.3f kilometers", rad/1e3)
    else
        rad_str = @sprintf("%.3f meters", rad)
    end
    long_str = position |> longitude |> sexagesimal
    lat_str  = position |>  latitude |> sexagesimal
    print(io, rad_str, ", ", long_str, ", ", lat_str)
end

function Base.show(io::IO, baseline::Baseline)
    str = @sprintf("%.3f meters, %.3f meters, %.3f meters", baseline.x, baseline.y, baseline.z)
    print(io, str)
end

macro epoch_str(sys)
    eval(current_module(),:(Measures.Epochs.$(Symbol(sys))))
end

macro dir_str(sys)
    eval(current_module(),:(Measures.Directions.$(Symbol(sys))))
end

macro pos_str(sys)
    eval(current_module(),:(Measures.Positions.$(Symbol(sys))))
end

macro baseline_str(sys)
    eval(current_module(),:(Measures.Baselines.$(Symbol(sys))))
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

"""
    measure(frame, value, newsys)

Converts the value measured in the given frame of reference into a new coordinate system.

**Arguments:**

* `frame` - an instance of the `ReferenceFrame` type
* `value` - an `Epoch`, `Direction`, or `Position` that will be converted from its current
            coordinate system into the new one
* `newsys` - the new coordinate system

Note that the reference frame must have all the required information to convert between the
coordinate systems. Not all conversions require the same information!

**Examples:**

``` julia
# Compute the azimuth and elevation of the Sun
measure(frame, Direction(dir"SUN"), dir"AZEL")

# Compute the ITRF position of the VLA
measure(frame, observatory("VLA"), pos"ITRF")

# Compute the atomic time from a UTC time
measure(frame, Epoch(epoch"UTC", 50237.29*u"d"), epoch"TAI")
```
"""
measure

"""
    sexagesimal(string)

Parse angles given in sexagesimal format.

The regular expression used here understands how to match hours and degrees.

**Examples:**

``` julia
sexagesimal("12h34m56.7s")
sexagesimal("+12d34m56.7s")
```
"""
function sexagesimal(str::AbstractString)
    # Explanation of the regular expression:
    # (\+|-)?       Capture a + or - sign if it is provided
    # (\d*\.?\d+)   Capture a decimal number (required)
    # (d|h)         Capture the letter d or the letter h (required)
    # (?:(\d*\.?\d+)m(?:(\d*\.?\d+)s)?)?
    #               Capture the decimal number preceding the letter m
    #               and if that is found, look for and capture the
    #               decimal number preceding the letter s
    regex = r"(\+|-)?(\d*\.?\d+)(d|h)(?:(\d*\.?\d+)m(?:(\d*\.?\d+)s)?)?"
    m = match(regex,str)
    m === nothing && err("Unknown sexagesimal format.")

    sign = m.captures[1] == "-" ? -1 : +1
    degrees_or_hours = float(m.captures[2])
    isdegrees = m.captures[3] == "d"
    minutes = m.captures[4] === nothing ? 0.0 : float(m.captures[4])
    seconds = m.captures[5] === nothing ? 0.0 : float(m.captures[5])

    minutes += seconds/60
    degrees_or_hours += minutes/60
    degrees = isdegrees ? degrees_or_hours : 15degrees_or_hours
    sign*degrees |> deg2rad
end

"""
    sexagesimal(angle; hours = false, digits = 0)

Construct a sexagesimal string from the given angle.

* If `hours` is `true`, the constructed string will use hours instead of degrees.
* `digits` specifies the number of decimal points to use for seconds/arcseconds.
"""
function sexagesimal(angle::T; hours::Bool = false, digits::Int = 0) where T
    if T <: Angle
        radians = uconvert(u"rad", angle) |> ustrip
    else
        radians = angle
    end
    if hours
        s = +1
        radians = mod2pi(radians)
    else
        s = sign(radians)
        radians = abs(radians)
    end
    if hours
        value = radians * 12/π
        value = round(value*3600, digits) / 3600
        q1 = floor(Int, value)
        s1 = @sprintf("%dh", q1)
        s < 0 && (s1 = "-"*s1)
    else
        value = radians * 180/π
        value = round(value*3600, digits) / 3600
        q1 = floor(Int, value)
        s1 = @sprintf("%dd", q1)
        s > 0 && (s1 = "+"*s1)
        s < 0 && (s1 = "-"*s1)
    end
    value = (value - q1) * 60
    q2 = floor(Int, value)
    s2 = @sprintf("%02dm", q2)
    value = (value - q2) * 60
    q3 = round(value, digits)
    s3 = @sprintf("%016.13f", q3)
    # remove the extra decimal places, but be sure to remove the
    # decimal point if we are removing all of the decimal places
    if digits == 0
        s3 = s3[1:2] * "s"
    else
        s3 = s3[1:digits+3] * "s"
    end
    string(s1, s2, s3)
end

Base.norm(measure::Measure) = hypot(measure.x, measure.y, measure.z) * u"m"
longitude(measure) = atan2(measure.y, measure.x) * u"rad"
latitude(measure)  = atan2(measure.z, hypot(measure.x, measure.y)) * u"rad"

function Base.isapprox(lhs::Epoch, rhs::Epoch)
    lhs.sys === rhs.sys || err("Coordinate systems must match.")
    lhs.time ≈ rhs.time
end

function Base.isapprox(lhs::T, rhs::T) where T<:Union{Direction,Position,Baseline}
    lhs.sys === rhs.sys || err("Coordinate systems must match.")
    v1 = [lhs.x, lhs.y, lhs.z]
    v2 = [rhs.x, rhs.y, rhs.z]
    v1 ≈ v2
end

mutable struct ReferenceFrame
    epoch :: Nullable{Epoch}
    direction :: Nullable{Direction}
    position :: Nullable{Position}
end

"""
    ReferenceFrame

The `ReferenceFrame` type contains information about the frame of reference to use when converting
between coordinate systems. For example converting from J2000 coordinates to AZEL coordinates
requires knowledge of the observer's location, and the current time. However converting between
B1950 coordinates and J2000 coordinates requires no additional information about the observer's
frame of reference.

Use the `set!` function to add information to the given frame of reference.

**Example:**

``` julia
frame = ReferenceFrame()
set!(frame, observatory("VLA")) # set the observer's position to the location of the VLA
set!(frame, Epoch(epoch"UTC", 50237.29*u"d")) # set the current UTC time
```
"""
function ReferenceFrame()
    ReferenceFrame(nothing, nothing, nothing)
end

set!(frame::ReferenceFrame, epoch::Epoch) = frame.epoch = epoch
set!(frame::ReferenceFrame, direction::Direction) = frame.direction = direction
set!(frame::ReferenceFrame, position::Position) = frame.position = position

# TODO we don't actually use the reference frame in the epoch conversions, can we come up with a
# new API that doesn't require it?

function measure(frame::ReferenceFrame, epoch::Epoch, newsys::Epochs.System)
    ccall(("convertEpoch", libcasacorewrapper), Epoch, (Ref{Epoch}, Cint), epoch, newsys)
end

function measure(frame::ReferenceFrame, direction::Direction, newsys::Directions.System)
    ccall(("convertDirection", libcasacorewrapper), Direction,
          (Ref{Direction}, Cint, Ref{ReferenceFrame}),
          direction, newsys, frame)
end

function measure(frame::ReferenceFrame, position::Position, newsys::Positions.System)
    ccall(("convertPosition", libcasacorewrapper), Position,
          (Ref{Position}, Cint, Ref{ReferenceFrame}),
          position, newsys, frame)
end

function measure(frame::ReferenceFrame, baseline::Baseline, newsys::Baselines.System)
    ccall(("convertBaseline", libcasacorewrapper), Baseline,
          (Ref{Baseline}, Cint, Ref{ReferenceFrame}),
          baseline, newsys, frame)
end

const VectorMeasure = Union{Direction, Position, Baseline}

for op in (:+, :-)
    @eval function Base.$op(measure1::T, measure2::T) where T<:VectorMeasure
        T(measure1.sys, $op(measure1.x, measure2.x),
                        $op(measure1.y, measure2.y),
                        $op(measure1.z, measure2.z))
    end
end

for op in (:*, :/)
    @eval function Base.$op(measure::T, scalar::Real) where T<:VectorMeasure
        T(measure.sys, $op(measure.x, scalar),
                       $op(measure.y, scalar),
                       $op(measure.z, scalar))
    end
    @eval function Base.$op(scalar::Real, measure::T) where T<:VectorMeasure
        T(measure.sys, $op(scalar, measure.x),
                       $op(scalar, measure.y),
                       $op(scalar, measure.z))
    end
end

function Base.dot(lhs::VectorMeasure, rhs::VectorMeasure)
    lhs.x*rhs.x + lhs.y*rhs.y + lhs.z*rhs.z
end

function Base.cross(lhs::T, rhs::T) where T<:VectorMeasure
    T(lhs.sys, lhs.y*rhs.z - lhs.z*rhs.y,
               lhs.z*rhs.x - lhs.x*rhs.z,
               lhs.x*rhs.y - lhs.y*rhs.x)
end

