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

@enum DirectionRef J2000 JMEAN JTRUE APP B1950 B1950_VLA BMEAN BTRUE GALACTIC HADEC AZEL AZELSW AZELGEO AZELSWGEO JNAT ECLIPTIC MECLIPTIC TECLIPTIC SUPERGAL MERCURY=32 VENUS MARS JUPITER SATURN URANUS NEPTUNE PLUTO SUN MOON

type Direction{ref} <: Measure
    ptr::Ptr{Void}
end

function Direction(ref::DirectionRef,longitude::Quantity,latitude::Quantity)
    direction = ccall(("newDirection",libcasacorewrapper), Ptr{Void},
                      (Ptr{Void},Ptr{Void},Cint),
                      pointer(longitude), pointer(latitude), ref) |> Direction{ref}
    finalizer(direction,delete)
    direction
end

Direction(longitude,latitude) = Direction(J2000,longitude,latitude)
Direction() = Direction(Quantity(Radian),Quantity(Radian))
Direction(ref::DirectionRef) = Direction(ref,Quantity(Radian),Quantity(Radian))

function delete(direction::Direction)
    ccall(("deleteDirection",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(direction))
end

pointer(direction::Direction) = direction.ptr
reference{ref}(::Direction{ref}) = ref

function longitude(direction::Direction, unit::Unit = Radian)
    ccall(("getDirectionLongitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(direction), pointer(unit))
end

function latitude(direction::Direction, unit::Unit = Radian)
    ccall(("getDirectionLatitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(direction), pointer(unit))
end

function show(io::IO, direction::Direction)
    long = longitude(direction,Degree)
    lat  = latitude(direction,Degree)
    print(io,"(",long," deg, ",lat," deg)")
end

function measure(frame::ReferenceFrame,direction::Direction,newref::DirectionRef)
    newdirection = ccall(("convertDirection",libcasacorewrapper), Ptr{Void},
                         (Ptr{Void},Cint,Ptr{Void}),
                         pointer(direction), newref, pointer(frame)) |> Direction{newref}
    finalizer(newdirection,delete)
    newdirection
end

