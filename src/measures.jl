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

abstract Measure
length{M<:Measure}(measure::M,str::ASCIIString) = length(measure,Unit(str))
longitude{M<:Measure}(measure::M,str::ASCIIString) = longitude(measure,Unit(str))
latitude{M<:Measure}(measure::M,str::ASCIIString) = latitude(measure,Unit(str))

