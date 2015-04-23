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

@enum PositionRef ITRF WGS84

type Position{ref} <: Measure
    ptr::Ptr{Void}
end

function Position(ref::PositionRef,length::Quantity,longitude::Quantity,latitude::Quantity)
    position = ccall(("newPosition",libcasacorewrapper), Ptr{Void},
                     (Ptr{Void},Ptr{Void},Ptr{Void},Cint),
                     pointer(length), pointer(longitude), pointer(latitude), ref) |> Position{ref}
    finalizer(position,delete)
    position
end

Position(length,longitude,latitude) = Position(ITRF,length,longitude,latitude)
Position() = Position(Quantity(Meter),Quantity(Radian),Quantity(Radian))

function delete(position::Position)
    ccall(("deletePosition",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(position))
end

pointer(position::Position) = position.ptr
reference{ref}(::Position{ref}) = ref

function length(position::Position, unit::Unit = Meter)
    ccall(("getLength",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(position), pointer(unit))
end

function longitude(position::Position, unit::Unit = Radian)
    ccall(("getPositionLongitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(position), pointer(unit))
end

function latitude(position::Position, unit::Unit = Radian)
    ccall(("getPositionLatitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(position), pointer(unit))
end

function show(io::IO, position::Position)
    L    = length(position,Meter)
    long = longitude(position,Degree)
    lat  = latitude(position,Degree)
    print(io,"(",L," m, ",long," deg, ",lat," deg)")
end

function measure(frame::ReferenceFrame,position::Position,newref::PositionRef)
    newposition = ccall(("convertPosition",libcasacorewrapper), Ptr{Void},
                        (Ptr{Void},Cint,Ptr{Void}),
                        pointer(position), newref, pointer(frame)) |> Position{newref}
    finalizer(newposition,delete)
    newposition
end

