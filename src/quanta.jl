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

"""
    Quantity(unit::Unit)

Construct a quantity where the value is set to zero.
"""
Quantity(unit::Unit) = Quantity(Float64(0.0),unit)

function delete(quantity::Quantity)
    ccall(("deleteQuantity",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(quantity))
end

pointer(quantity::Quantity) = quantity.ptr

function get(quantity::Quantity, unit::Unit)
    ccall(("getQuantity",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(quantity), pointer(unit))
end

# TODO: replace this with something more robust
include("radec.jl")

