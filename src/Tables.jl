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

"The `Tables` module is used to interact with CasaCore tables."
module Tables

export CasaCoreTablesError
export Table

const libcasacorewrapper = joinpath(@__DIR__, "..", "deps", "src", "libcasacorewrapper.so")

function __init__()
    isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")
end

struct CasaCoreTablesError <: Exception
    msg :: String
end
Base.show(io::IO, err::CasaCoreTablesError) = print(io, "CasaCoreTablesError: ", err.msg)
err(msg) = throw(CasaCoreTablesError(msg))

include("tables/types.jl")
include("tables/tables.jl")
include("tables/rows.jl")
include("tables/columns.jl")







#"""
#    Tables.lock(table::Table; writelock = true, attempts = 5)
#
#Attempt to get a lock on the given table. Throws an `ErrorException` if a lock is not obtained after
#the given number of attempts.
#"""
#function lock(table::Table; writelock::Bool=true, attempts::Int=5)
#    success = ccall(("lock", libcasacorewrapper), Bool,
#                    (Ptr{Void}, Bool, Cint), table, writelock, attempts)
#    success || error("Could not get a lock on the table.")
#    nothing
#end
#
#"""
#    Tables.unlock(table::Table)
#
#Clear any locks obtained on the given table.
#"""
#function Base.unlock(table::Table)
#    ccall(("unlock", libcasacorewrapper), Void, (Ptr{Void},), table)
#end
#
#"""
#    numkeywords(table::Table)
#
#Returns the number of keywords associated with the given table.
#"""
#numkeywords(table::Table) = Int(ccall(("nkeyword", libcasacorewrapper), Cuint, (Ptr{Void},), table))
#
#Base.size(table::Table) = (numrows(table), numcolumns(table))
#
#struct Keyword
#    name::String
#end
#
#Base.convert(::Type{String}, keyword::Keyword) = keyword.name
#function Base.unsafe_convert(::Type{Ptr{Cchar}}, keyword::Keyword)
#    Base.unsafe_convert(Ptr{Cchar}, String(keyword))
#end
#Base.show(io::IO, keyword::Keyword) = print(io, keyword.name)
#
#macro kw_str(string)
#    quote
#        Keyword($string)
#    end
#end
#
#"""
#    Tables.remove_keyword!(table::Table, keyword::Keyword)
#
#Remove the specified keyword from the table.
#"""
#function remove_keyword!(table::Table, keyword::Keyword)
#    ccall(("removeKeyword", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}), table, keyword)
#end
#
#function remove_keyword!(table::Table, column::String, keyword::Keyword)
#    ccall(("removeKeyword_column", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
#          table, column, keyword)
#end
#
#"Query the data type of the keyword."
#function keyword_type(table::Table, keyword::Keyword)
#    enum = ccall(("getKeywordType", libcasacorewrapper), Cint, (Ptr{Void}, Ptr{Cchar}),
#                 table, keyword)
#    enum2type[TypeEnum(enum)]
#end
#
#function keyword_type(table::Table, column::String, keyword::Keyword)
#    enum = ccall(("getKeywordType_column", libcasacorewrapper), Cint,
#                 (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
#    enum2type[TypeEnum(enum)]
#end
#
#"Query whether the keyword exists."
#function keyword_exists(table::Table, keyword::Keyword)
#    ccall(("keywordExists", libcasacorewrapper), Bool, (Ptr{Void}, Ptr{Cchar}), table, keyword)
#end
#
#function keyword_exists(table::Table, column::String, keyword::Keyword)
#    ccall(("keywordExists_column", libcasacorewrapper), Bool, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
#          table, column, keyword)
#end
#
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
#
## Read/Write Keywords
#
#function getindex(table::Table, keyword::Keyword)
#    if !keyword_exists(table, keyword)
#        throw(CasaCoreError("the keyword \"$keyword\" is not present in this table"))
#    end
#    T = keyword_type(table, keyword)
#    read_keyword(table, keyword, T)
#end
#
#function setindex!(table::Table, value, keyword::Keyword)
#    if keyword_exists(table, keyword)
#        T = keyword_type(table, keyword)
#        if T != eltype(value)
#            throw(CasaCoreError("type mismatch for keyword \"$keyword\""))
#        end
#    end
#    write_keyword!(table, value, keyword)
#end
#
#function getindex(table::Table, column::String, keyword::Keyword)
#    if !column_exists(table, column)
#        throw(CasaCoreError("the column \"$column\" is not present in this table"))
#    end
#    if !keyword_exists(table, column, keyword)
#        throw(CasaCoreError("the keyword \"$keyword\" is not present in this table"))
#    end
#    T = keyword_type(table, column, keyword)
#    read_keyword(table, column, keyword, T)
#end
#
#function setindex!(table::Table, value, column::String, keyword::Keyword)
#    if !column_exists(table, column)
#        throw(CasaCoreError("the column \"$column\" is not present in this table"))
#    end
#    if keyword_exists(table, column, keyword)
#        T = keyword_type(table, column, keyword)
#        if T != eltype(value)
#            throw(CasaCoreError("type mismatch for keyword \"$keyword\""))
#        end
#    end
#    write_keyword!(table, value, column, keyword)
#end
#
#for T in typelist_nostring
#    typestr = type2str[T]
#    c_getKeyword        = "getKeyword_$typestr"
#    c_getKeyword_column = "getKeyword_column_$typestr"
#    c_putKeyword        = "putKeyword_$typestr"
#    c_putKeyword_column = "putKeyword_column_$typestr"
#
#    @eval function read_keyword(table::Table, keyword::Keyword, ::Type{$T})
#        ccall(($c_getKeyword, libcasacorewrapper), $T, (Ptr{Void}, Ptr{Cchar}), table, keyword)
#    end
#
#    @eval function read_keyword(table::Table, column::String, keyword::Keyword, ::Type{$T})
#        ccall(($c_getKeyword_column, libcasacorewrapper), $T, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
#              table, column, keyword)
#    end
#
#    @eval function write_keyword!(table::Table, value::$T, keyword::Keyword)
#        ccall(($c_putKeyword, libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, $T),
#              table, keyword, value)
#        value
#    end
#
#    @eval function write_keyword!(table::Table, value::$T, column::String, keyword::Keyword)
#        ccall(($c_putKeyword_column, libcasacorewrapper), Void,
#              (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}, $T), table, column, keyword, value)
#        value
#    end
#end
#
#function read_keyword(table::Table, keyword::Keyword, ::Type{String})
#    ptr = ccall(("getKeyword_string", libcasacorewrapper), Ptr{Cchar}, (Ptr{Void}, Ptr{Cchar}),
#                table, keyword)
#    unsafe_wrap(String, ptr, true)
#end
#
#function read_keyword(table::Table, column::String, keyword::Keyword, ::Type{String})
#    ptr = ccall(("getKeyword_column_string", libcasacorewrapper), Ptr{Cchar},
#                (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
#    unsafe_wrap(String, ptr, true)
#end
#
#function write_keyword!(table::Table, value::String, keyword::Keyword)
#    ccall(("putKeyword_string", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
#          table, keyword, value)
#    value
#end
#
#function write_keyword!(table::Table, value::String, column::String, keyword::Keyword)
#    ccall(("putKeyword_column_string", libcasacorewrapper), Void,
#          (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword, value)
#    value
#end

end

