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

export observatory, sexagesimal

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
            ccall(($cxx_convert,libcasacorewrapper), Ptr{Void},
                  (Ptr{Void}, Ptr{Void}, Cint), frame, x, newsys) |> $cxx_name |> to_julia
        end
    end |> esc
end

macro wrap_pointer(name)
    cxx_delete = string("delete", name)
    cxx_new    = string("new", name)
    quote
        type $name
            ptr :: Ptr{Void}
        end
        Base.unsafe_convert(::Type{Ptr{Void}}, x::$name) = x.ptr
        delete(x::$name) = ccall(($cxx_delete,libcasacorewrapper), Void, (Ptr{Void},), x)
        function $name()
            y = ccall(($cxx_new,libcasacorewrapper), Ptr{Void}, ()) |> $name
            finalizer(y, delete)
            y
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
    Epoch(sys, time, unit)

Instantiate an epoch in the given coordinate system.

Note that the time should be a modified Julian date.

**Examples:**

    Epoch(epoch"UTC",     0.0, "d") # 1858-11-17T00:00:00
    Epoch(epoch"UTC", 57365.5, "d") # 2015-12-09T12:00:00
"""
function Epoch(sys::Epochs.System, time::Float64, unit::ASCIIString)
    ccall(("newEpoch_with_units",libcasacorewrapper), Ptr{Void},
          (Cint, Float64, Cstring), sys, time, unit) |> Epoch_cxx |> to_julia
end

"""
    Direction(sys, longitude, latitude)

Instantiate a direction in the given coordinate system.

Note that the longitude and latitude should be given as sexagesimal strings.

**Examples:**

    Direction(dir"AZEL", "0d", "90d") # topocentric zenith
    Direction(dir"J2000", "12h00m", "43d21m")
"""
function Direction(sys::Directions.System, longitude::ASCIIString, latitude::ASCIIString)
    long = sexagesimal(longitude)
    lat  = sexagesimal(latitude)
    ccall(("newDirection_longlat",libcasacorewrapper), Ptr{Void},
          (Cint, Float64, Float64), sys, long, lat) |> Direction_cxx |> to_julia
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

"""
function Position(sys::Positions.System, elevation::Float64, longitude::ASCIIString, latitude::ASCIIString)
    long = sexagesimal(longitude)
    lat  = sexagesimal(latitude)
    ccall(("newPosition_elevationlonglat",libcasacorewrapper), Ptr{Void},
          (Cint, Float64, Float64, Float64), sys, elevation, long, lat) |> Position_cxx |> to_julia
end

function Base.show(io::IO, epoch::Epoch)
    julian_date = 2400000.5 + epoch.time/(24*60*60)
    print(io, Dates.julian2datetime(julian_date))
end

function Base.show(io::IO, direction::Direction)
    long_str = @sprintf("%.5f°, ", longitude(direction))
    lat_str =  @sprintf("%.5f°",    latitude(direction))
    print(io, long_str, lat_str)
end

function Base.show(io::IO, position::Position)
    rad = radius(position)
    if rad > 1e5
        rad_str = @sprintf("%.3f kilometers, ", rad/1e3)
    else
        rad_str = @sprintf("%.3f meters, ", rad)
    end
    long_str = @sprintf("%.5f°, ", longitude(position))
    lat_str =  @sprintf("%.5f°",    latitude(position))
    print(io, rad_str, long_str, lat_str)
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
    sexagesimal(str) -> radians

Parse angles given in sexagesimal format.

The regular expression used here understands how to match
hours and degrees.

**Examples:**

    sexagesimal("12h34m56.7s")
    sexagesimal("+12d34m56.7s")
"""
function sexagesimal(str::ASCIIString)
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

radius(measure) = hypot(hypot(measure.x, measure.y), measure.z)
longitude(measure) = atan2(measure.y, measure.x) |> rad2deg
latitude(measure)  = atan2(measure.z, hypot(measure.x, measure.y)) |> rad2deg

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

