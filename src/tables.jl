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

module Tables

export Table, @kw_str

importall Base.Operators
using Compat
import Compat.String
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

const type2str  = ObjectIdDict(Bool           => "boolean",
                               Int32          => "int",
                               Float32        => "float",
                               Float64        => "double",
                               Complex64      => "complex",
                               String         => "string",
                               Vector{String} => "arraystring")

const enum2type = ObjectIdDict(TpBool        => Bool,
                               TpInt         => Int32,
                               TpFloat       => Float32,
                               TpDouble      => Float64,
                               TpComplex     => Complex64,
                               TpString      => String,
                               TpArrayString => Vector{String})

"""
    type Table

This type is used to interact with CasaCore tables (including
Measurement Sets).
"""
@wrap_pointer Table

"""
    Table(name::AbstractString)

Open and lock the CasaCore table. If no table with the given name
exists, a new table is created.
"""
function Table(name::AbstractString)
    # Remove the "Table: " prefix, if it exists
    strippedname = replace(name,"Table: ","",1)
    if isdir(strippedname)
        table = ccall(("newTable_existing",libcasacorewrapper), Ptr{Void}, (Ptr{Cchar},), strippedname) |> Table
    else
        table = ccall(("newTable_create",libcasacorewrapper), Ptr{Void}, (Ptr{Cchar},), strippedname) |> Table
    end
    finalizer(table,delete)
    table
end

function Base.show(io::IO, table::Table)
    N = ccall(("name_length",libcasacorewrapper), Int, (Ptr{Void},), table)
    output = Array(Cchar, N)
    ccall(("name",libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}), table, output)
    chars = [Char(x) for x in output]
    print(io, "Table: ", String(chars))
end

Base.iswritable(table::Table) = ccall(("iswritable",libcasacorewrapper), Bool, (Ptr{Void},), table)
Base.isreadable(table::Table) = ccall(("isreadable",libcasacorewrapper), Bool, (Ptr{Void},), table)

"""
    lock(table::Table; writelock = true, attempts = 5)

Attempt to get a lock on the given table.

Throws an `ErrorException` if a lock is not obtained after the given number of attempts.
"""
function Base.lock(table::Table; writelock::Bool=true, attempts::Int=5)
    success = ccall(("lock",libcasacorewrapper), Bool,
                    (Ptr{Void},Bool,Cint), table, writelock, attempts)
    success || error("Could not get a lock on the table.")
    nothing
end

"""
    unlock(table::Table)

Clear any locks obtained on the given table.
"""
function Base.unlock(table::Table)
    ccall(("unlock",libcasacorewrapper), Void, (Ptr{Void},), table)
end

"""
    numrows(table::Table)

Returns the number of rows in the given table.
"""
numrows(table::Table)     = ccall(("numrows",    libcasacorewrapper), Cint, (Ptr{Void},), table)

"""
    numcolumns(table::Table)

Returns the number of columns in the given table.
"""
numcolumns(table::Table)  = ccall(("numcolumns", libcasacorewrapper), Cint, (Ptr{Void},), table)

"""
    numkeywords(table::Table)

Returns the number of keywords associated with the given table.
"""
numkeywords(table::Table) = ccall(("numkeywords",libcasacorewrapper), Cint, (Ptr{Void},), table)

Base.size(table::Table) = (numrows(table),numcolumns(table))

"""
    addrows!(table::Table, nrows)

Add the given number of rows to the table.
"""
function addrows!(table::Table, nrows::Integer)
    ccall(("addRow",libcasacorewrapper), Void, (Ptr{Void},Cint), table, nrows)
end

function Base.delete!(table::Table, column::AbstractString)
    ccall(("removeColumn",libcasacorewrapper), Void, (Ptr{Void},Ptr{Cchar}), table, column)
end

# Read/Write Columns

function exists(table::Table, column::AbstractString)
    ccall(("columnExists",libcasacorewrapper), Bool, (Ptr{Void}, Ptr{Cchar}), table, column)
end

function column_info(table::Table, column::AbstractString)
    # what data type is stored in this column?
    enum = ccall(("getColumnType",libcasacorewrapper), Cint, (Ptr{Void},Ptr{Cchar}), table, column)
    T = enum2type[TypeEnum(enum)]
    # how many dimensions does the column have?
    N = ccall(("getColumnDim",libcasacorewrapper), Cint, (Ptr{Void},Ptr{Cchar}), table, column)
    # what is the size of each dimension?
    shape = zeros(Cint,N)
    ccall(("getColumnShape",libcasacorewrapper), Void, (Ptr{Void},Ptr{Cchar},Ptr{Cint}), table, column, shape)
    T, shape
end

function getindex(table::Table, column::AbstractString)
    exists(table, column) || error("Column $column does not exist.")
    T,S = column_info(table, column)
    array = Array(T,S...)
    read_into!(array, table, column)
    array
end

function setindex!(table::Table, value, column::AbstractString)
    # creates the column if it doesn't already exist
    write_to!(table, column, value)
end

# Read/Write Cells

function getindex(table::Table, column::AbstractString, row::Int)
    exists(table, column) || error("Column $column does not exist.")
    T,S = column_info(table, column)
    array = Array(T,S[1:end-1]...)
    read_into!(array, table, column, row)
    length(S) == 1 && return array[1] # return a scalar when possible
    array
end

function setindex!(table::Table, value, column::AbstractString, row::Int)
    exists(table,column) || error("Column $column does not exist.")
    write_to!(table, column, row, value)
end

# Read/Write Keywords

immutable Keyword
    name::String
end

Base.convert(::Type{String}, keyword::Keyword) = keyword.name
Base.unsafe_convert(::Type{Ptr{Cchar}}, keyword::Keyword) = Base.unsafe_convert(Ptr{Cchar}, keyword |> String)

macro kw_str(string)
    quote
        Keyword($string)
    end
end

function exists(table::Table, column::AbstractString, keyword::Keyword)
    ccall(("keywordExists",libcasacorewrapper), Bool,
          (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
end

function keyword_info(table::Table, column::AbstractString, keyword::Keyword)
    # what data type is stored in this keyword?
    enum = ccall(("getKeywordType",libcasacorewrapper), Cint,
                   (Ptr{Void},Ptr{Cchar},Ptr{Cchar}), table, column ,keyword)
    T = enum2type[TypeEnum(enum)]
    T
end

function getindex(table::Table, keyword::Keyword)
    exists(table, "", keyword) || error("Keyword does not exist.")
    T = keyword_info(table, "", keyword)
    read_keyword(table, "", keyword, T)
end

function getindex(table::Table, column::AbstractString, keyword::Keyword)
    exists(table, column) || error("Column does not exist.")
    exists(table, column, keyword) || error("Keyword does not exist.")
    T = keyword_info(table, column, keyword)
    read_keyword(table, column, keyword, T)
end

function setindex!(table::Table, value, keyword::Keyword)
    write_keyword!(table, "", keyword, value)
end

function setindex!(table::Table, value, column::AbstractString, keyword::Keyword)
    exists(table, column)  || error("Column does not exist.")
    write_keyword!(table, column, keyword, value)
end

# Define all the functions for all the types!

for T in (Bool,Int32,Float32,Float64,Complex64)
    typestr = type2str[T]
    c_addScalarColumn = "addScalarColumn_$typestr"
    c_addArrayColumn  = "addArrayColumn_$typestr"
    c_getColumn       = "getColumn_$typestr"
    c_putColumn       = "putColumn_$typestr"
    c_getCell         = "getCell_$typestr"
    c_putCell         = "putCell_$typestr"
    c_putCell_scalar  = "putCell_scalar_$typestr"
    c_getKeyword      = "getKeyword_$typestr"
    c_putKeyword      = "putKeyword_$typestr"

    @eval function create_column!(table::Table, column::AbstractString, ::Type{$T}, shape)
        if length(shape) == 1
            ccall(($c_addScalarColumn,libcasacorewrapper), Void,
                  (Ptr{Void},Ptr{Cchar}), table, column)
        else
            ccall(($c_addArrayColumn,libcasacorewrapper), Void,
                  (Ptr{Void},Ptr{Cchar},Ptr{Cint},Cint),
                  table, column, shape[1:end-1] |> Vector{Cint}, length(shape)-1)
        end
    end

    @eval function read_into!(output::Array{$T}, table::Table, column::AbstractString)
        ccall(($c_getColumn,libcasacorewrapper), Void,
              (Ptr{Void},Ptr{Cchar},Ptr{$T},Cint),
              table, column, output, length(output))
        output
    end

    @eval function write_to!(table::Table, column::AbstractString, input::Array{$T})
        shape = [size(input)...] |> Vector{Cint}
        ndim  = length(shape)
        exists(table, column) || create_column!(table, column, $T, shape)
        ccall(($c_putColumn,libcasacorewrapper), Void,
              (Ptr{Void},Ptr{Cchar},Ptr{$T},Ptr{Cint},Cint),
              table, column, input, shape, ndim)
        input
    end

    @eval function read_into!(output::Array{$T},table::Table,
                              column::AbstractString,row::Int)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($c_getCell,libcasacorewrapper), Void,
              (Ptr{Void},Ptr{Cchar},Cint,Ptr{$T},Cint),
              table, column, row-1, output, length(output))
        output
    end

    @eval function write_to!(table::Table, column::AbstractString, row::Int, input::Array{$T})
        shape = [size(input)...] |> Vector{Cint}
        ndim  = length(shape)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($c_putCell,libcasacorewrapper), Void,
              (Ptr{Void},Ptr{Cchar},Cint,Ptr{$T},Ptr{Cint},Cint),
              table, column, row-1, input, shape, ndim)
        input
    end

    @eval function write_to!(table::Table, column::AbstractString, row::Int, input::$T)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($c_putCell_scalar,libcasacorewrapper), Void,
              (Ptr{Void},Ptr{Cchar},Cint,$T),
              table, column, row-1, input)
        input
    end

    @eval function read_keyword(table::Table, column::AbstractString, keyword::Keyword, ::Type{$T})
        ccall(($c_getKeyword,libcasacorewrapper), $T,
              (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
              table, column, keyword)
    end

    @eval function write_keyword!(table::Table, column::AbstractString, keyword::Keyword, input::$T)
        ccall(($c_putKeyword,libcasacorewrapper), Void,
              (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}, $T),
              table, column, keyword, input)
    end
end

# Strings are special little snow flakes and need to be treated separately.

function read_keyword(table::Table, column::AbstractString, keyword::Keyword, ::Type{String})
    N = ccall(("getKeyword_string_length",libcasacorewrapper), Int,
              (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
    output = Array(Cchar, N)
    ccall(("getKeyword_string",libcasacorewrapper), Void,
          (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}),
          table, column, keyword, output)
    chars = [Char(x) for x in output]
    String(chars)
end

function write_keyword!(table::Table, column::AbstractString, keyword::Keyword, input::AbstractString)
    ccall(("putKeyword_string",libcasacorewrapper), Void,
          (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}),
          table, column, keyword, input)
end

end

