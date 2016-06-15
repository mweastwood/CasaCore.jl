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

module Measures

export Epoch, Direction, Position, Baseline
export @epoch_str, @dir_str, @pos_str, @baseline_str

export ReferenceFrame
export set!, measure

export radius, longitude, latitude, observatory, sexagesimal
export seconds, days, degrees, radians, meters

using ..Common

const libcasacorewrapper = joinpath(dirname(@__FILE__),"../deps/libcasacorewrapper.so")
isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")

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

"""
This module provides basic support for dispatching on units.
This is intended *only* for interacting with CasaCore.Measures.

Todo: Replace this with SIUnits once that package gets the
love and affection it clearly needs.
"""
module Units
    abstract Unit
    abstract Time <: Unit
    abstract Angle <: Unit
    abstract Distance <: Unit

    immutable Second <: Time val :: Float64 end
    immutable Day    <: Time val :: Float64 end
    Second(x::Second) = x
    Second(x::Day) = Second(x.val * 24*60*60)
    Day(x::Second) = Day(x.val / (24*60*60))

    immutable Degree <: Angle val :: Float64 end
    immutable Radian <: Angle val :: Float64 end
    Radian(x::Radian) = x
    Radian(x::Degree) = Radian(x.val * π/180)

    immutable Meter <: Distance val :: Float64 end
    Meter(x::Meter) = x

    importall Base.Operators
    *{T<:Unit}(num::Real, unit::T) = T(num*unit.val)
    value(unit::Unit) = unit.val
end

const seconds = Units.Second(1.0)
const days    = Units.Day(1.0)
const degrees = Units.Degree(1.0)
const radians = Units.Radian(1.0)
const meters  = Units.Meter(1.0)

macro wrap(expr)
    jl_name  = expr.args[2].args[1]
    jl_names = symbol(jl_name, "s")
    cxx_name = symbol(jl_name, "_cxx")
    cxx_delete  = string("delete", jl_name)  # delete the corresponding C++ object
    cxx_new     = string("new", jl_name)     # create a new corresponding C++ object
    cxx_get     = string("get", jl_name)     # bring the C++ object back to Julia
    cxx_set     = string("set", jl_name)     # attach the measure to a frame of reference
    cxx_convert = string("convert", jl_name) # convert the measure to a new coordinate system

    quote
        Base.@__doc__ $expr # the original expression
        type $cxx_name
            ptr :: Ptr{Void}
        end
        Base.unsafe_convert(::Type{Ptr{Void}}, x::$cxx_name) = x.ptr
        Base.unsafe_convert(::Type{Ptr{Void}}, x::$jl_name) = Base.unsafe_convert(Ptr{Void}, x |> to_cxx)
        delete(x::$cxx_name) = ccall(($cxx_delete,libcasacorewrapper), Void, (Ptr{Void},), x)
        function to_cxx(x::$jl_name)
            y = ccall(($cxx_new,libcasacorewrapper), Ptr{Void}, ($jl_name,), x) |> $cxx_name
            finalizer(y, delete)
            y
        end
        to_julia(x::$cxx_name) = ccall(($cxx_get,libcasacorewrapper), $jl_name, (Ptr{Void},), x)
        function set!(frame::ReferenceFrame, x::$jl_name)
            ccall(($cxx_set,libcasacorewrapper), Void, (Ptr{Void}, Ptr{Void}), frame, x)
        end
        function measure(frame::ReferenceFrame, x::$jl_name, newsys::$jl_names.System)
            (ccall(($cxx_convert,libcasacorewrapper), Ptr{Void},
                   (Ptr{Void}, Ptr{Void}, Cint), frame, x, newsys) |> $cxx_name |> to_julia) :: $jl_name
        end
    end |> esc
end

@wrap_pointer ReferenceFrame
abstract Measure

"""
    immutable Epoch <: Measure

This type represents an instance in time.
"""
@wrap immutable Epoch <: Measure
    sys  :: Epochs.System
    time :: Float64 # measured in seconds
end

"""
    immutable Direction <: Measure

This type represents a location on the sky.
"""
@wrap immutable Direction <: Measure
    sys :: Directions.System
    x :: Float64 # measured in meters
    y :: Float64 # measured in meters
    z :: Float64 # measured in meters
end

"""
    immutable Position <: Measure

This type represents a location on the surface of the Earth.
"""
@wrap immutable Position <: Measure
    sys :: Positions.System
    x :: Float64 # measured in meters
    y :: Float64 # measured in meters
    z :: Float64 # measured in meters
end

"""
    immutable Baseline <: Measure

This type represents the location of one antenna relative to another antenna.
"""
@wrap immutable Baseline <: Measure
    sys :: Baselines.System
    x :: Float64 # measured in meters
    y :: Float64 # measured in meters
    z :: Float64 # measured in meters
end

"""
    Epoch(sys, time)

Instantiate an epoch in the given coordinate system.

Note that the time should be a modified Julian date.

**Examples:**

    Epoch(epoch"UTC",     0.0days) # 1858-11-17T00:00:00
    Epoch(epoch"UTC", 57365.5days) # 2015-12-09T12:00:00
"""
function Epoch(sys::Epochs.System, time)
    seconds = Units.Second(time) |> Units.value
    Epoch(sys, seconds)
end

"""
    Direction(sys, longitude, latitude)

Instantiate a direction in the given coordinate system.

Note that the longitude and latitude should be given as sexagesimal strings.

**Examples:**

    Direction(dir"AZEL", 0degrees, 90degrees) # topocentric zenith
    Direction(dir"J2000", "12h00m", "43d21m")
"""
function Direction(sys::Directions.System, longitude::Units.Angle, latitude::Units.Angle)
    long = Units.Radian(longitude) |> Units.value
    lat  = Units.Radian( latitude) |> Units.value
    (ccall(("newDirection_longlat",libcasacorewrapper), Ptr{Void},
           (Cint, Float64, Float64), sys, long, lat) |> Direction_cxx |> to_julia) :: Direction
end

function Direction(sys::Directions.System, longitude::AbstractString, latitude::AbstractString)
    Direction(sys, sexagesimal(longitude)*radians, sexagesimal(latitude)*radians)
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
function Direction(sys::Directions.System)
    Direction(sys, 1.0, 0.0, 0.0)
end

"""
    Position(sys, elevation, longitude, latitude)

Instantiate a position in the given coordinate system.

Note that depending on the coordinate system the elevation
may be measured relative to the center or the surface of the Earth.
In both cases it should be specified in meters.

The longitude and latitude should be given as sexagesimal strings.

**Examples:**

    Position(pos"WGS84", 5_000meters, "20d30m00s", "-80d00m00s")
    Position(pos"WGS84", 5_000meters, 20.5degrees, -80degrees)
"""
function Position(sys::Positions.System, elevation::Units.Distance,
                  longitude::Units.Angle, latitude::Units.Angle)
    rad  = Units.Meter( elevation) |> Units.value
    long = Units.Radian(longitude) |> Units.value
    lat  = Units.Radian( latitude) |> Units.value
    (ccall(("newPosition_elevationlonglat",libcasacorewrapper), Ptr{Void},
           (Cint, Float64, Float64, Float64), sys, rad, long, lat) |> Position_cxx |> to_julia) :: Position
end

function Position(sys::Positions.System, elevation::Units.Distance,
                  longitude::AbstractString, latitude::AbstractString)
    Position(sys, elevation, sexagesimal(longitude)*radians, sexagesimal(latitude)*radians)
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
    rad = radius(position)
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
    eval(current_module(),:(Measures.Epochs.$(symbol(sys))))
end

macro dir_str(sys)
    eval(current_module(),:(Measures.Directions.$(symbol(sys))))
end

macro pos_str(sys)
    eval(current_module(),:(Measures.Positions.$(symbol(sys))))
end

macro baseline_str(sys)
    eval(current_module(),:(Measures.Baselines.$(symbol(sys))))
end

"""
    observatory(name::ASCIIString)

Get the position of an observatory from its name.

**Examples:**

    observatory("VLA")  # the Very Large Array
    observatory("ALMA") # the Atacama Large Millimeter/submillimeter Array
"""
function observatory(name::ASCIIString)
    position = Position(pos"ITRF", 0.0, 0.0, 0.0) |> Ref{Position}
    status = ccall(("observatory",libcasacorewrapper), Bool,
                   (Ref{Position}, Cstring), position, name)
    !status && error("Unknown observatory.")
    position[]
end

"""
    sexagesimal(string)

Parse angles given in sexagesimal format.

The regular expression used here understands how to match
hours and degrees.

**Examples:**

    sexagesimal("12h34m56.7s")
    sexagesimal("+12d34m56.7s")
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
    m === nothing && error("Unknown sexagesimal format.")

    sign = m.captures[1] == "-"? -1 : +1
    degrees_or_hours = float(m.captures[2])
    isdegrees = m.captures[3] == "d"
    minutes = m.captures[4] === nothing? 0.0 : float(m.captures[4])
    seconds = m.captures[5] === nothing? 0.0 : float(m.captures[5])

    minutes += seconds/60
    degrees_or_hours += minutes/60
    degrees = isdegrees? degrees_or_hours : 15degrees_or_hours
    sign*degrees |> deg2rad
end

"""
    sexagesimal(angle; hours = false, digits = 0)

Construct a sexagesimal string from the given angle.

* If `hours` is `true`, the constructed string will use hours instead of degrees.
* `digits` specifies the number of decimal points to use for seconds/arcseconds.
"""
function sexagesimal(angle; hours::Bool = false, digits::Int = 0)
    radians = Units.Radian(angle) |> Units.value
    s = sign(radians); radians = abs(radians)
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

radius(measure) = hypot(hypot(measure.x, measure.y), measure.z)
longitude(measure) = atan2(measure.y, measure.x)
latitude(measure)  = atan2(measure.z, hypot(measure.x, measure.y))

function Base.≈(lhs::Epoch, rhs::Epoch)
    lhs.sys === rhs.sys || error("Coordinate systems must match.")
    lhs.time ≈ rhs.time
end

function Base.≈{T<:Union{Direction,Position,Baseline}}(lhs::T, rhs::T)
    lhs.sys === rhs.sys || error("Coordinate systems must match.")
    v1 = [lhs.x, lhs.y, lhs.z]
    v2 = [rhs.x, rhs.y, rhs.z]
    v1 ≈ v2
end

end

