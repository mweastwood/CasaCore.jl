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

const libcasacorewrapper = joinpath(dirname(@__FILE__),"../deps/libcasacorewrapper.so")
isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")

@enum(TypeEnum,
      TpBool, TpChar, TpUChar, TpShort, TpUShort, TpInt, TpUInt,
      TpFloat, TpDouble, TpComplex, TpDComplex, TpString, TpTable,
      TpArrayBool, TpArrayChar, TpArrayUChar, TpArrayShort, TpArrayUShort,
      TpArrayInt, TpArrayUInt, TpArrayFloat, TpArrayDouble, TpArrayComplex,
      TpArrayDComplex, TpArrayString, TpRecord, TpOther, TpQuantity,
      TpArrayQuantity, TpInt64, TpArrayInt64, TpNumberOfTypes)

const type2str = ObjectIdDict()
const str2type = Dict{ASCIIString,Type}()
const type2enum = ObjectIdDict()
const enum2type = ObjectIdDict()

for (T,str,enum) in ((Bool,"boolean",TpBool),
                     (Int32,"int",TpInt),
                     (Float32,"float",TpFloat),
                     (Float64,"double",TpDouble),
                     (Complex64,"complex",TpComplex),
                     (ASCIIString,"string",TpString),
                     (Vector{ASCIIString},"arraystring",TpArrayString))
    type2str[T] = str
    str2type[str] = T
    type2enum[T] = enum
    enum2type[enum] = T
end

