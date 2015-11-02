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

"""
    type Unit

This type represents a unit of measure (eg. a second, a meter,
or a degree).

Note that this type should not be used for unit-checked computation
within Julia. Rather it should be used exclusively for interacting
with CasaCore.
"""
type Unit
    ptr::Ptr{Void}
end

"""
    Unit(str::ASCIIString)

Construct a unit from its string representation.

**Examples:**

    Unit("s") # a second
    Unit("d") # a day
    Unit("m") # a meter
    Unit("rad") # a radian
    Unit("deg") # a degree
"""
function Unit(str::ASCIIString)
    unit = ccall(("newUnit",libcasacorewrapper), Ptr{Void},
                 (Ptr{Cchar},), pointer(str)) |> Unit
    finalizer(unit,delete)
    unit
end

function delete(unit::Unit)
    ccall(("deleteUnit",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(unit))
end

pointer(unit::Unit) = unit.ptr

"""
    type Quantity

This type represents a number with its associated unit
(eg. 3 seconds, 5 degrees, or 12.6 meters).

Note that this type should not be used for unit-checked computation
within Julia. Rather it should be used exclusively for interacting
with CasaCore.
"""
type Quantity
    ptr::Ptr{Void}
end

"""
    Quantity(val::Float64, unit::Unit)

Construct a quantity from its value and associated unit.
"""
function Quantity(val::Float64,unit::Unit)
    quantity = ccall(("newQuantity",libcasacorewrapper), Ptr{Void},
                     (Cdouble,Ptr{Void},),val,  pointer(unit)) |> Quantity
    finalizer(quantity,delete)
    quantity
end

Quantity(val::Float64,str::ASCIIString) = Quantity(val,Unit(str))

"""
    Quantity(unit::Unit)

Construct a quantity where the value is set to zero.
"""
Quantity(unit::Unit) = Quantity(Float64(0.0),unit)

macro q_str(str)
    try
        deg = sexagesimal(str)
        return Quantity(deg,Unit("deg"))
    catch
        regex = r"(\d*\.?\d+)\s*(.+)"
        m = match(regex,str)
        value = float(m.captures[1])
        unit  = ascii(m.captures[2])
        return Quantity(value,unit)
    end
end

function delete(quantity::Quantity)
    ccall(("deleteQuantity",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(quantity))
end

pointer(quantity::Quantity) = quantity.ptr

function get(quantity::Quantity, unit::Unit)
    ccall(("getQuantity",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(quantity), pointer(unit))
end

get(quantity::Quantity,str::ASCIIString) = get(quantity,Unit(str))

"""
    sexagesimal(str) -> degrees

Parse angles given in sexagesimal format.

The regular expression used here understands how to match
hours and degrees.

**Examples:**

    sexagesimal("12h34m56.7s")
    sexagesimal("+12d34m56.7s")
"""
function sexagesimal(str)
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
    sign*degrees
end

abstract Measure{sys}
pointer(measure::Measure) = measure.ptr
coordinate_system{sys}(::Measure{sys}) = sys

"""
    @measure(T,N)

This macro defines the type, constructor, and finalizer for `Epoch`, `Direction`,
`Position`, and `Baseline`.
"""
macro measure(T,N)
    if isa(T,Expr)
        T = T.args[1]
    end

    types_of = symbol("Types_of_",string(T),"s")
    new      = string("new",T)
    delete   = string("delete",T)

    type_definition = quote
        type $T{sys} <: Measure{sys}
            ptr::Ptr{Void}
        end
    end

    # the constructor needs to accept a variable number of arguments and
    # pass them all to a ccall, so we need to build it by hand
    constructor_definition = quote
        function $T(sys::$types_of.System)
            measure = ccall(($new,libcasacorewrapper), Ptr{Void}, (Cint,), sys) |> $T{sys}
            finalizer(measure, delete)
            measure
        end
    end
    header = constructor_definition.args[2].args[1]
    body   = constructor_definition.args[2].args[2]
    ccall_ = body.args[2].args[2].args[2]
    ccall_.head == :ccall || error("Couldn't find the ccall.")
    for n = 1:N
        name = symbol("q",n)
        push!(header.args, :($name::Quantity))
        push!(ccall_.args, :(pointer($name)))
        push!(ccall_.args[3].args, :(Ptr{Void}))
    end

    finalizer_definition = quote
        function delete(measure::$T)
            ccall(($delete,libcasacorewrapper), Void, (Ptr{Void},), pointer(measure))
        end
    end

    esc(quote
        $type_definition
        $constructor_definition
        $finalizer_definition
    end)
end

doc"""
    @add_vector_like_methods(T)

This macro defines `length`, `longitude`, `latitude`, and `vector`
for vector-like measures (that is `Direction`, `Position`, and `Baseline`).

It also defines an additional constructor that takes the Cartesian vector
$(x,y,z)$ (in units of meters) to construct the measure.
"""
macro add_vector_like_methods(T)
    if isa(T,Expr)
        T = T.args[1]
    end

    types_of     = symbol("Types_of_",string(T),"s")
    newXYZ       = string("new",T,"XYZ")
    getLength    = string("get",T,"Length")
    getLongitude = string("get",T,"Longitude")
    getLatitude  = string("get",T,"Latitude")
    getXYZ       = string("get",T,"XYZ")

    constructor_definition = quote
        function $T(sys::$types_of.System, x::Float64, y::Float64, z::Float64)
            measure = ccall(($newXYZ,libcasacorewrapper), Ptr{Void},
                            (Cint,Cdouble,Cdouble,Cdouble), sys, x, y, z) |> $T{sys}
            finalizer(measure, delete)
            measure
        end
    end

    accessors_definition = quote
        function length(measure::$T, unit::Unit = Unit("m"))
            ccall(($getLength,libcasacorewrapper), Cdouble,
                  (Ptr{Void},Ptr{Void}), pointer(measure), pointer(unit))
        end
        function longitude(measure::$T, unit::Unit = Unit("rad"))
            ccall(($getLongitude,libcasacorewrapper), Cdouble,
                  (Ptr{Void},Ptr{Void}), pointer(measure), pointer(unit))
        end
        function latitude(measure::$T, unit::Unit = Unit("rad"))
            ccall(($getLatitude,libcasacorewrapper), Cdouble,
                  (Ptr{Void},Ptr{Void}), pointer(measure), pointer(unit))
        end
        function vector(measure::$T)
            x = Ref{Cdouble}(0)
            y = Ref{Cdouble}(0)
            z = Ref{Cdouble}(0)
            ccall(($getXYZ,libcasacorewrapper), Void,
                  (Ptr{Void},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble}),
                  pointer(measure), x, y, z)
            x[],y[],z[]
        end
    end

    esc(quote
        $constructor_definition
        $accessors_definition
    end)
end

length(measure::Measure,str::ASCIIString) = length(measure,Unit(str))
longitude(measure::Measure,str::ASCIIString) = longitude(measure,Unit(str))
latitude(measure::Measure,str::ASCIIString) = latitude(measure,Unit(str))

