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

################################################################################
# Units

type Unit
    ptr::Ptr{Void}
end

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

const Second = Unit("s")
const Day    = Unit("d")
const Radian = Unit("rad")
const Degree = Unit("deg")
const Meter  = Unit("m")

################################################################################
# Quantities

type Quantity
    ptr::Ptr{Void}
end

function Quantity(val::Float64,unit::Unit)
    quantity = ccall(("newQuantity",libcasacorewrapper), Ptr{Void},
                     (Cdouble,Ptr{Void},),val,  pointer(unit)) |> Quantity
    finalizer(quantity,delete)
    quantity
end

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

################################################################################
# Miscellaneous

include("radec.jl")

