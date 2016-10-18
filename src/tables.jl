# Copyright (c) 2015, 2016 Michael Eastwood
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

"The `Tables` module is used to interact with CasaCore tables."
module Tables

export CasaCoreError
export Table, @kw_str

importall Base.Operators
using ..Common

const libcasacorewrapper = joinpath(dirname(@__FILE__),"../deps/libcasacorewrapper.so")
isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")

@enum(TypeEnum,
      TpBool, TpChar, TpUChar, TpShort, TpUShort, TpInt, TpUInt,
      TpFloat, TpDouble, TpComplex, TpDComplex, TpString, TpTable,
      TpArrayBool, TpArrayChar, TpArrayUChar, TpArrayShort, TpArrayUShort,
      TpArrayInt, TpArrayUInt, TpArrayFloat, TpArrayDouble, TpArrayComplex,
      TpArrayDComplex, TpArrayString, TpRecord, TpOther, TpQuantity,
      TpArrayQuantity, TpInt64, TpArrayInt64, TpNumberOfTypes)

const type2str  = ObjectIdDict(Bool       => "boolean", Int32      => "int",
                               Float32    => "float",   Float64    => "double",
                               Complex64  => "complex", String     => "string")

const enum2type = ObjectIdDict(TpBool    => Bool,      TpInt     => Int32,
                               TpFloat   => Float32,   TpDouble  => Float64,
                               TpComplex => Complex64, TpString  => String)

const typelist = (Bool, Int32, Float32, Float64, Complex64, String)
const typelist_nostring = (Bool, Int32, Float32, Float64, Complex64)

"""
    Table

This type is used to interact with CasaCore tables (including Measurement Sets).

    Table(path::String)

Open and lock the CasaCore table. If no table at the given path exists, a new table is created.
"""
@wrap_pointer Table

function Table(path::String)
    # Remove the "Table: " prefix, if it exists
    path = replace(path, "Table: ", "", 1)
    # Expand a tilde to the home directory
    path = expanduser(path)
    if isdir(path)
        ptr = ccall(("newTable_update", libcasacorewrapper), Ptr{Void}, (Ptr{Cchar},), path)
    else
        ptr = ccall(("newTable_create", libcasacorewrapper), Ptr{Void}, (Ptr{Cchar},), path)
    end
    table = Table(ptr)
    finalizer(table, delete)
    table
end

function Base.show(io::IO, table::Table)
    c_str = ccall(("tableName", libcasacorewrapper), Ptr{Cchar}, (Ptr{Void},), table)
    j_str = unsafe_wrap(String, c_str, true)
    print(io, "Table: ", j_str)
end

"""
    Tables.lock(table::Table; writelock = true, attempts = 5)

Attempt to get a lock on the given table. Throws an `ErrorException` if a lock is not obtained after
the given number of attempts.
"""
function lock(table::Table; writelock::Bool=true, attempts::Int=5)
    success = ccall(("lock", libcasacorewrapper), Bool,
                    (Ptr{Void}, Bool, Cint), table, writelock, attempts)
    success || error("Could not get a lock on the table.")
    nothing
end

"""
    Tables.unlock(table::Table)

Clear any locks obtained on the given table.
"""
function Base.unlock(table::Table)
    ccall(("unlock", libcasacorewrapper), Void, (Ptr{Void},), table)
end

"""
    Tables.numrows(table::Table)

Returns the number of rows in the given table.
"""
numrows(table::Table) = Int(ccall(("nrow", libcasacorewrapper), Cuint, (Ptr{Void},), table))

"""
    numcolumns(table::Table)

Returns the number of columns in the given table.
"""
numcolumns(table::Table)  = Int(ccall(("ncolumn", libcasacorewrapper), Cuint, (Ptr{Void},), table))

"""
    numkeywords(table::Table)

Returns the number of keywords associated with the given table.
"""
numkeywords(table::Table) = Int(ccall(("nkeyword", libcasacorewrapper), Cuint, (Ptr{Void},), table))

Base.size(table::Table) = (numrows(table), numcolumns(table))

"""
    Tables.addrows!(table::Table, numrows)

Add the given number of rows to the table.
"""
function addrows!(table::Table, numrows::Integer)
    ccall(("addRow", libcasacorewrapper), Void, (Ptr{Void}, Cuint), table, numrows)
end

"""
    Tables.removerows!(table::Table, rows)

Remove the specified rows from the table.
"""
function removerows!(table::Table, rows)
    c_rows = collect(rows-1)
    ccall(("removeRow", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cuint}, Csize_t),
          table, c_rows, length(c_rows))
end

for T in typelist
    typestr = type2str[T]
    c_addScalarColumn = "addScalarColumn_$typestr"
    c_addArrayColumn  = "addArrayColumn_$typestr"

    @eval function addcolumn!(table::Table, column::String, ::Type{$T}, shape::Tuple{Int})
        ccall(($c_addScalarColumn, libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}),
              table, column)
    end

    @eval function addcolumn!(table::Table, column::String, ::Type{$T}, shape::Tuple)
        cell_shape = convert(Vector{Cint}, collect(shape[1:end-1]))
        ccall(($c_addArrayColumn, libcasacorewrapper), Void,
              (Ptr{Void}, Ptr{Cchar}, Ptr{Cint}, Cint),
              table, column, cell_shape, length(cell_shape))
    end
end

"""
    Tables.removecolumn!(table::Table, column::String)

Remove the specified column from the table. Note that removing columns from a reference table does
not remove the columns from the original table.
"""
function removecolumn!(table::Table, column::String)
    ccall(("removeColumn", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}), table, column)
end

"Query the element type of the given column."
function column_eltype(table::Table, column::String)
    enum = ccall(("getColumnType", libcasacorewrapper), Cint, (Ptr{Void}, Ptr{Cchar}),
                 table, column)
    enum2type[TypeEnum(enum)]
end

"Query the dimensionality of the given column."
function column_dim(table::Table, column::String)
    ccall(("getColumnDim", libcasacorewrapper), Cint, (Ptr{Void}, Ptr{Cchar}), table, column)
end

"Query the shape of the given column."
function column_shape(table::Table, column::String)
    N = column_dim(table, column)
    ptr = ccall(("getColumnShape", libcasacorewrapper), Ptr{Cint}, (Ptr{Void}, Ptr{Cchar}),
                table, column)
    vec = unsafe_wrap(Vector{Cint}, ptr, N, true)
    tuple(convert(Vector{Int}, vec)...)
end

"Query whether the column exists."
function column_exists(table::Table, column::String)
    ccall(("columnExists", libcasacorewrapper), Bool, (Ptr{Void}, Ptr{Cchar}), table, column)
end

immutable Keyword
    name::String
end

Base.convert(::Type{String}, keyword::Keyword) = keyword.name
function Base.unsafe_convert(::Type{Ptr{Cchar}}, keyword::Keyword)
    Base.unsafe_convert(Ptr{Cchar}, String(keyword))
end
Base.show(io::IO, keyword::Keyword) = print(io, keyword.name)

macro kw_str(string)
    quote
        Keyword($string)
    end
end

"""
    Tables.removekeyword!(table::Table, keyword::Keyword)

Remove the specified keyword from the table.
"""
function removekeyword!(table::Table, keyword::Keyword)
    ccall(("removeKeyword", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}), table, keyword)
end

function removekeyword!(table::Table, column::String, keyword::Keyword)
    ccall(("removeKeyword_column", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
          table, column, keyword)
end

"Query the data type of the keyword."
function keyword_type(table::Table, keyword::Keyword)
    enum = ccall(("getKeywordType", libcasacorewrapper), Cint, (Ptr{Void}, Ptr{Cchar}),
                 table, keyword)
    enum2type[TypeEnum(enum)]
end

function keyword_type(table::Table, column::String, keyword::Keyword)
    enum = ccall(("getKeywordType_column", libcasacorewrapper), Cint,
                 (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
    enum2type[TypeEnum(enum)]
end

"Query whether the keyword exists."
function keyword_exists(table::Table, keyword::Keyword)
    ccall(("keywordExists", libcasacorewrapper), Bool, (Ptr{Void}, Ptr{Cchar}), table, keyword)
end

function keyword_exists(table::Table, column::String, keyword::Keyword)
    ccall(("keywordExists_column", libcasacorewrapper), Bool, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
          table, column, keyword)
end

# Read/Write Columns

function getindex(table::Table, column::String)
    if !column_exists(table, column)
        throw(CasaCoreError("the column \"$column\" is not present in this table"))
    end
    T = column_eltype(table, column)
    shape = column_shape(table, column)
    read_column(table, column, T, shape)
end

function setindex!(table::Table, value, column::String)
    if !column_exists(table, column)
        addcolumn!(table, column, eltype(value), size(value))
    end
    T = column_eltype(table, column)
    if T != eltype(value)
        throw(CasaCoreError("element type mismatch for column \"$column\""))
    end
    shape = column_shape(table, column)
    if shape != size(value)
        throw(CasaCoreError("array shape mismatch for column \"$column\""))
    end
    write_column!(table, value, column)
end

for T in typelist_nostring
    typestr = type2str[T]
    c_getColumn = "getColumn_$typestr"
    c_putColumn = "putColumn_$typestr"

    @eval function read_column(table::Table, column::String, ::Type{$T}, shape)
        N = length(shape)
        ptr = ccall(($c_getColumn, libcasacorewrapper), Ptr{$T}, (Ptr{Void}, Ptr{Cchar}),
                    table, column)
        unsafe_wrap(Array{$T, N}, ptr, shape, true)
    end

    @eval function write_column!(table::Table, value::Array{$T}, column::String)
        shape = convert(Vector{Cint}, collect(size(value)))
        ccall(($c_putColumn, libcasacorewrapper), Void,
              (Ptr{Void}, Ptr{Cchar}, Ptr{$T}, Ptr{Cint}, Cint),
              table, column, value, shape, length(shape))
        value
    end
end

function read_column(table::Table, column::String, ::Type{String}, shape)
    N = length(shape)
    ptr = ccall(("getColumn_string", libcasacorewrapper), Ptr{Ptr{Cchar}},
                (Ptr{Void}, Ptr{Cchar}), table, column)
    arr = unsafe_wrap(Array{Ptr{Cchar}, N}, ptr, shape, true)
    [unsafe_wrap(String, my_ptr, true) for my_ptr in arr]
end

function write_column!(table::Table, value::Array{String}, column::String)
    shape = convert(Vector{Cint}, collect(size(value)))
    ccall(("putColumn_string", libcasacorewrapper), Void,
          (Ptr{Void}, Ptr{Cchar}, Ptr{Ptr{Cchar}}, Ptr{Cint}, Cint),
          table, column, value, shape, length(shape))
    value
end

# Read/Write Cells

function getindex(table::Table, column::String, row::Int)
    if !column_exists(table, column)
        throw(CasaCoreError("the column \"$column\" is not present in this table"))
    end
    if row ≤ 0 || row > numrows(table)
        throw(CasaCoreError("row number out of range"))
    end
    T = column_eltype(table, column)
    shape = column_shape(table, column)[1:end-1]
    read_cell(table, column, row, T, shape)
end

function setindex!(table::Table, value, column::String, row::Int)
    if !column_exists(table, column)
        throw(CasaCoreError("the column \"$column\" is not present in this table"))
    end
    if row ≤ 0 || row > numrows(table)
        throw(CasaCoreError("row number out of range"))
    end
    check_cell_type(table, column, value)
    check_cell_size(table, column, value)
    write_cell!(table, value, column, row)
end

function check_cell_type(table, column, value::Array)
    T = column_eltype(table, column)
    if T != eltype(value)
        throw(CasaCoreError("element type mismatch for column \"$column\""))
    end
end

function check_cell_type(table, column, value)
    T = column_eltype(table, column)
    if T != typeof(value)
        throw(CasaCoreError("element type mismatch for column \"$column\""))
    end
end

function check_cell_size(table, column, value::Array)
    shape = column_shape(table, column)[1:end-1]
    if shape != size(value)
        throw(CasaCoreError("shape mismatch for cell in column \"$column\""))
    end
end

function check_cell_size(table, column, value)
    shape = column_shape(table, column)
    if length(shape) != 1
        throw(CasaCoreError("shape mismatch for cell in column \"$column\""))
    end
end

for T in typelist_nostring
    typestr = type2str[T]
    c_getCell_scalar = "getCell_scalar_$typestr"
    c_getCell_array  = "getCell_array_$typestr"
    c_putCell_scalar = "putCell_scalar_$typestr"
    c_putCell_array  = "putCell_array_$typestr"

    @eval function read_cell(table::Table, column::String, row::Int, ::Type{$T}, shape::Tuple{})
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($c_getCell_scalar, libcasacorewrapper), $T, (Ptr{Void}, Ptr{Cchar}, Cuint),
              table, column, row-1)
    end

    @eval function read_cell(table::Table, column::String, row::Int, ::Type{$T}, shape::Tuple)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        N = length(shape)
        ptr = ccall(($c_getCell_array, libcasacorewrapper), Ptr{$T}, (Ptr{Void}, Ptr{Cchar}, Cuint),
                    table, column, row-1)
        unsafe_wrap(Array{$T, N}, ptr, shape, true)
    end

    @eval function write_cell!(table::Table, value::$T, column::String, row::Int)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($c_putCell_scalar, libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, Cuint, $T),
              table, column, row-1, value)
        value
    end

    @eval function write_cell!(table::Table, value::Array{$T}, column::String, row::Int)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        shape = convert(Vector{Cint}, collect(size(value)))
        ccall(($c_putCell_array, libcasacorewrapper), Void,
              (Ptr{Void}, Ptr{Cchar}, Cuint, Ptr{$T}, Ptr{Cint}, Cint),
              table, column, row-1, value, shape, length(shape))
        value
    end
end

function read_cell(table::Table, column::String, row::Int, ::Type{String}, shape::Tuple{})
    # Subtract 1 from the row number to convert to a 0-based indexing scheme
    ptr = ccall(("getCell_scalar_string", libcasacorewrapper), Ptr{Cchar},
                (Ptr{Void}, Ptr{Cchar}, Cuint), table, column, row-1)
    unsafe_wrap(String, ptr, true)
end

function read_cell(table::Table, column::String, row::Int, ::Type{String}, shape::Tuple)
    # Subtract 1 from the row number to convert to a 0-based indexing scheme
    N = length(shape)
    ptr = ccall(("getCell_array_string", libcasacorewrapper), Ptr{Ptr{Cchar}},
                (Ptr{Void}, Ptr{Cchar}, Cuint), table, column, row-1)
    arr = unsafe_wrap(Array{Ptr{Cchar}, N}, ptr, shape, true)
    [unsafe_wrap(String, my_ptr, true) for my_ptr in arr]
end

function write_cell!(table::Table, value::String, column::String, row::Int)
    # Subtract 1 from the row number to convert to a 0-based indexing scheme
    ccall(("putCell_scalar_string", libcasacorewrapper), Void,
          (Ptr{Void}, Ptr{Cchar}, Cuint, Ptr{Cchar}), table, column, row-1, value)
    value
end

function write_cell!(table::Table, value::Array{String}, column::String, row::Int)
    # Subtract 1 from the row number to convert to a 0-based indexing scheme
    shape = convert(Vector{Cint}, collect(size(value)))
    ccall(("putCell_array_string", libcasacorewrapper), Void,
          (Ptr{Void}, Ptr{Cchar}, Cuint, Ptr{Ptr{Cchar}}, Ptr{Cint}, Cint),
          table, column, row-1, value, shape, length(shape))
    value
end

# Read/Write Keywords

function getindex(table::Table, keyword::Keyword)
    if !keyword_exists(table, keyword)
        throw(CasaCoreError("the keyword \"$keyword\" is not present in this table"))
    end
    T = keyword_type(table, keyword)
    read_keyword(table, keyword, T)
end

function setindex!(table::Table, value, keyword::Keyword)
    if keyword_exists(table, keyword)
        T = keyword_type(table, keyword)
        if T != eltype(value)
            throw(CasaCoreError("type mismatch for keyword \"$keyword\""))
        end
    end
    write_keyword!(table, value, keyword)
end

function getindex(table::Table, column::String, keyword::Keyword)
    if !column_exists(table, column)
        throw(CasaCoreError("the column \"$column\" is not present in this table"))
    end
    if !keyword_exists(table, column, keyword)
        throw(CasaCoreError("the keyword \"$keyword\" is not present in this table"))
    end
    T = keyword_type(table, column, keyword)
    read_keyword(table, column, keyword, T)
end

function setindex!(table::Table, value, column::String, keyword::Keyword)
    if !column_exists(table, column)
        throw(CasaCoreError("the column \"$column\" is not present in this table"))
    end
    if keyword_exists(table, column, keyword)
        T = keyword_type(table, column, keyword)
        if T != eltype(value)
            throw(CasaCoreError("type mismatch for keyword \"$keyword\""))
        end
    end
    write_keyword!(table, value, column, keyword)
end

for T in typelist_nostring
    typestr = type2str[T]
    c_getKeyword        = "getKeyword_$typestr"
    c_getKeyword_column = "getKeyword_column_$typestr"
    c_putKeyword        = "putKeyword_$typestr"
    c_putKeyword_column = "putKeyword_column_$typestr"

    @eval function read_keyword(table::Table, keyword::Keyword, ::Type{$T})
        ccall(($c_getKeyword, libcasacorewrapper), $T, (Ptr{Void}, Ptr{Cchar}), table, keyword)
    end

    @eval function read_keyword(table::Table, column::String, keyword::Keyword, ::Type{$T})
        ccall(($c_getKeyword_column, libcasacorewrapper), $T, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
              table, column, keyword)
    end

    @eval function write_keyword!(table::Table, value::$T, keyword::Keyword)
        ccall(($c_putKeyword, libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, $T),
              table, keyword, value)
        value
    end

    @eval function write_keyword!(table::Table, value::$T, column::String, keyword::Keyword)
        ccall(($c_putKeyword_column, libcasacorewrapper), Void,
              (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}, $T), table, column, keyword, value)
        value
    end
end

function read_keyword(table::Table, keyword::Keyword, ::Type{String})
    ptr = ccall(("getKeyword_string", libcasacorewrapper), Ptr{Cchar}, (Ptr{Void}, Ptr{Cchar}),
                table, keyword)
    unsafe_wrap(String, ptr, true)
end

function read_keyword(table::Table, column::String, keyword::Keyword, ::Type{String})
    ptr = ccall(("getKeyword_column_string", libcasacorewrapper), Ptr{Cchar},
                (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
    unsafe_wrap(String, ptr, true)
end

function write_keyword!(table::Table, value::String, keyword::Keyword)
    ccall(("putKeyword_string", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
          table, keyword, value)
    value
end

function write_keyword!(table::Table, value::String, column::String, keyword::Keyword)
    ccall(("putKeyword_column_string", libcasacorewrapper), Void,
          (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword, value)
    value
end

end

