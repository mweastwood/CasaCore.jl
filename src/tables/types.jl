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

@enum(TypeEnum,
      TpBool, TpChar, TpUChar, TpShort, TpUShort, TpInt, TpUInt,
      TpFloat, TpDouble, TpComplex, TpDComplex, TpString, TpTable,
      TpArrayBool, TpArrayChar, TpArrayUChar, TpArrayShort, TpArrayUShort,
      TpArrayInt, TpArrayUInt, TpArrayFloat, TpArrayDouble, TpArrayComplex,
      TpArrayDComplex, TpArrayString, TpRecord, TpOther, TpQuantity,
      TpArrayQuantity, TpInt64, TpArrayInt64, TpNumberOfTypes)

const type2str  = ObjectIdDict(Bool       => :boolean, Int32      => :int,
                               Float32    => :float,   Float64    => :double,
                               Complex64  => :complex, String     => :string)

const enum2type = Dict(TpBool    => Bool,      TpInt     => Int32,
                       TpFloat   => Float32,   TpDouble  => Float64,
                       TpComplex => Complex64, TpString  => String)

const typelist = (Bool, Int32, Float32, Float64, Complex64, String)
const typelist_nostring = (Bool, Int32, Float32, Float64, Complex64)

