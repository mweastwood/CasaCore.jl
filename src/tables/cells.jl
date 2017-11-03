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

## Read/Write Cells
#
#function getindex(table::Table, column::String, row::Int)
#    if !column_exists(table, column)
#        throw(CasaCoreError("the column \"$column\" is not present in this table"))
#    end
#    if row ≤ 0 || row > numrows(table)
#        throw(CasaCoreError("row number out of range"))
#    end
#    T = column_eltype(table, column)
#    shape = column_shape(table, column)[1:end-1]
#    read_cell(table, column, row, T, shape)
#end
#
#function setindex!(table::Table, value, column::String, row::Int)
#    if !column_exists(table, column)
#        throw(CasaCoreError("the column \"$column\" is not present in this table"))
#    end
#    if row ≤ 0 || row > numrows(table)
#        throw(CasaCoreError("row number out of range"))
#    end
#    check_cell_type(table, column, value)
#    check_cell_size(table, column, value)
#    write_cell!(table, value, column, row)
#end
#
#function check_cell_type(table, column, value::Array)
#    T = column_eltype(table, column)
#    if T != eltype(value)
#        throw(CasaCoreError("element type mismatch for column \"$column\""))
#    end
#end
#
#function check_cell_type(table, column, value)
#    T = column_eltype(table, column)
#    if T != typeof(value)
#        throw(CasaCoreError("element type mismatch for column \"$column\""))
#    end
#end
#
#function check_cell_size(table, column, value::Array)
#    shape = column_shape(table, column)[1:end-1]
#    if shape != size(value)
#        throw(CasaCoreError("shape mismatch for cell in column \"$column\""))
#    end
#end
#
#function check_cell_size(table, column, value)
#    shape = column_shape(table, column)
#    if length(shape) != 1
#        throw(CasaCoreError("shape mismatch for cell in column \"$column\""))
#    end
#end
#
#for T in typelist_nostring
#    typestr = type2str[T]
#    c_getCell_scalar = "getCell_scalar_$typestr"
#    c_getCell_array  = "getCell_array_$typestr"
#    c_putCell_scalar = "putCell_scalar_$typestr"
#    c_putCell_array  = "putCell_array_$typestr"
#
#    @eval function read_cell(table::Table, column::String, row::Int, ::Type{$T}, shape::Tuple{})
#        # Subtract 1 from the row number to convert to a 0-based indexing scheme
#        ccall(($c_getCell_scalar, libcasacorewrapper), $T, (Ptr{Void}, Ptr{Cchar}, Cuint),
#              table, column, row-1)
#    end
#
#    @eval function read_cell(table::Table, column::String, row::Int, ::Type{$T}, shape::Tuple)
#        # Subtract 1 from the row number to convert to a 0-based indexing scheme
#        N = length(shape)
#        ptr = ccall(($c_getCell_array, libcasacorewrapper), Ptr{$T}, (Ptr{Void}, Ptr{Cchar}, Cuint),
#                    table, column, row-1)
#        unsafe_wrap(Array{$T, N}, ptr, shape, true)
#    end
#
#    @eval function write_cell!(table::Table, value::$T, column::String, row::Int)
#        # Subtract 1 from the row number to convert to a 0-based indexing scheme
#        ccall(($c_putCell_scalar, libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, Cuint, $T),
#              table, column, row-1, value)
#        value
#    end
#
#    @eval function write_cell!(table::Table, value::Array{$T}, column::String, row::Int)
#        # Subtract 1 from the row number to convert to a 0-based indexing scheme
#        shape = convert(Vector{Cint}, collect(size(value)))
#        ccall(($c_putCell_array, libcasacorewrapper), Void,
#              (Ptr{Void}, Ptr{Cchar}, Cuint, Ptr{$T}, Ptr{Cint}, Cint),
#              table, column, row-1, value, shape, length(shape))
#        value
#    end
#end
#
#function read_cell(table::Table, column::String, row::Int, ::Type{String}, shape::Tuple{})
#    # Subtract 1 from the row number to convert to a 0-based indexing scheme
#    ptr = ccall(("getCell_scalar_string", libcasacorewrapper), Ptr{Cchar},
#                (Ptr{Void}, Ptr{Cchar}, Cuint), table, column, row-1)
#    unsafe_wrap(String, ptr, true)
#end
#
#function read_cell(table::Table, column::String, row::Int, ::Type{String}, shape::Tuple)
#    # Subtract 1 from the row number to convert to a 0-based indexing scheme
#    N = length(shape)
#    ptr = ccall(("getCell_array_string", libcasacorewrapper), Ptr{Ptr{Cchar}},
#                (Ptr{Void}, Ptr{Cchar}, Cuint), table, column, row-1)
#    arr = unsafe_wrap(Array{Ptr{Cchar}, N}, ptr, shape, true)
#    [unsafe_wrap(String, my_ptr, true) for my_ptr in arr]
#end
#
#function write_cell!(table::Table, value::String, column::String, row::Int)
#    # Subtract 1 from the row number to convert to a 0-based indexing scheme
#    ccall(("putCell_scalar_string", libcasacorewrapper), Void,
#          (Ptr{Void}, Ptr{Cchar}, Cuint, Ptr{Cchar}), table, column, row-1, value)
#    value
#end
#
#function write_cell!(table::Table, value::Array{String}, column::String, row::Int)
#    # Subtract 1 from the row number to convert to a 0-based indexing scheme
#    shape = convert(Vector{Cint}, collect(size(value)))
#    ccall(("putCell_array_string", libcasacorewrapper), Void,
#          (Ptr{Void}, Ptr{Cchar}, Cuint, Ptr{Ptr{Cchar}}, Ptr{Cint}, Cint),
#          table, column, row-1, value, shape, length(shape))
#    value
#end

