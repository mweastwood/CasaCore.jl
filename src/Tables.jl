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

const libcasacorewrapper = normpath(joinpath(@__DIR__, "..", "deps", "src",
                                             "libcasacorewrapper.so"))

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
include("tables/cells.jl")







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

