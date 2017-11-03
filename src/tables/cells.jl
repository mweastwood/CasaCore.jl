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

function Base.getindex(table::Table, column::String, row::Integer)
    check_column_row(table, column, row)
    T, shape = column_info(table, column)
    read_cell(table, column, row, T, shape[1:end-1])
end

function Base.setindex!(table::Table, value, column::String, row::Integer)
    check_column_row(table, column, row)
    T, shape = column_info(table, column)
    check_cell(value, column, T, shape)
    write_cell!(table, value, column, row)
end

function check_column_row(table, column, row)
    if !column_exists(table, column)
        column_missing_error(column)
    end
    if row ≤ 0 || row > num_rows(table)
        row_out_of_bounds_error(row)
    end
end

function check_cell(value::Array, column, T, shape)
    if T != eltype(value)
        column_element_type_error(column)
    end
    if shape[1:end-1] != size(value)
        column_shape_error(column)
    end
end

function check_cell(value, column, T, shape)
    if T != typeof(value)
        column_element_type_error(column)
    end
    if length(shape) != 1
        column_shape_error(column)
    end
end

for T in typelist
    Tc = type2cpp[T]
    typestr = type2str[T]
    c_get_cell_scalar = String(Symbol(:get_cell_scalar_, typestr))
    c_get_cell_array  = String(Symbol(:get_cell_array_,  typestr))
    c_put_cell_scalar = String(Symbol(:put_cell_scalar_, typestr))
    c_put_cell_array  = String(Symbol(:put_cell_array_,  typestr))

    @eval function read_cell(table::Table, column::String, row::Int, ::Type{$T}, shape::Tuple{})
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        value = ccall(($c_get_cell_scalar, libcasacorewrapper), $Tc,
                      (Ptr{CasaCoreTable}, Ptr{Cchar}, Cuint), table, column, row-1)
        wrap_value(value)
    end

    @eval function read_cell(table::Table, column::String, row::Int, ::Type{$T}, shape::Tuple)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ptr = ccall(($c_get_cell_array, libcasacorewrapper), Ptr{$Tc},
                    (Ptr{CasaCoreTable}, Ptr{Cchar}, Cuint), table, column, row-1)
        wrap(ptr, shape)
    end

    @eval function write_cell!(table::Table, value::$T, column::String, row::Int)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($c_put_cell_scalar, libcasacorewrapper), Void,
              (Ptr{CasaCoreTable}, Ptr{Cchar}, Cuint, $Tc), table, column, row-1, value)
        value
    end

    @eval function write_cell!(table::Table, value::Array{$T}, column::String, row::Int)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        shape = convert(Vector{Cint}, collect(size(value)))
        ccall(($c_put_cell_array, libcasacorewrapper), Void,
              (Ptr{CasaCoreTable}, Ptr{Cchar}, Cuint, Ptr{$Tc}, Ptr{Cint}, Cint),
              table, column, row-1, value, shape, length(shape))
        value
    end
end

