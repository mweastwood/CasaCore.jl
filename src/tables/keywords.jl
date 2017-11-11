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

@noinline function keyword_missing_error(keyword)
    err("keyword \"$keyword\" is missing from the table")
end

@noinline function keyword_element_type_error(keyword)
    err("element type mismatch for keyword \"$keyword\"")
end

struct Keyword
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
    numkeywords(table::Table)

Returns the number of keywords associated with the given table.
"""
function num_keywords(table::Table)
    ccall((:num_keywords, libcasacorewrapper), Cuint,
          (Ptr{CasaCoreTable},), table) |> Int
end

"Query whether the keyword exists."
function keyword_exists(table::Table, keyword::Keyword)
    ccall((:keyword_exists, libcasacorewrapper), Bool,
          (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
end

#function keyword_exists(table::Table, column::String, keyword::Keyword)
#    ccall(("keywordExists_column", libcasacorewrapper), Bool, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
#          table, column, keyword)
#end

"""
    Tables.remove_keyword!(table::Table, keyword::Keyword)

Remove the specified keyword from the table.
"""
function remove_keyword!(table::Table, keyword::Keyword)
    ccall((:remove_keyword, libcasacorewrapper), Void,
          (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
    keyword
end

#function remove_keyword!(table::Table, column::String, keyword::Keyword)
#    ccall(("removeKeyword_column", libcasacorewrapper), Void, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
#          table, column, keyword)
#end

"Get the keyword element type and shape."
function keyword_info(table::Table, keyword::Keyword)
    element_type = Ref{Cint}(0)
    dimension    = Ref{Cint}(0)
    shape_ptr = ccall((:keyword_info, libcasacorewrapper), Ptr{Cint},
                      (Ptr{CasaCoreTable}, Ptr{Cchar}, Ref{Cint}, Ref{Cint}),
                      table, keyword, element_type, dimension)
    T = enum2type[TypeEnum(element_type[])]
    shape = unsafe_wrap(Vector{Cint}, shape_ptr, dimension[], true)
    T, tuple(shape...)
end

#function keyword_type(table::Table, column::String, keyword::Keyword)
#    enum = ccall(("getKeywordType_column", libcasacorewrapper), Cint,
#                 (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
#    enum2type[TypeEnum(enum)]
#end

function Base.getindex(table::Table, keyword::Keyword)
    if !keyword_exists(table, keyword)
        keyword_missing_error(keyword)
    end
    T, shape = keyword_info(table, keyword)
    read_keyword(table, keyword, T, shape)
end

function Base.setindex!(table::Table, value, keyword::Keyword)
    if keyword_exists(table, keyword)
        T, shape = keyword_info(table, keyword)
        if T != typeof(value)
            keyword_element_type_error(keyword)
        end
    end
    write_keyword!(table, value, keyword)
end

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
for T in typelist
    Tc = type2cpp[T]
    typestr = type2str[T]
    c_get_keyword        = String(Symbol(:get_keyword_, typestr))
    c_get_keyword_array  = String(Symbol(:get_keyword_array_, typestr))
    #c_get_keyword_column = String(Symbol(:get_keyword_column_, typestr))
    c_put_keyword        = String(Symbol(:put_keyword_, typestr))
    c_put_keyword_array  = String(Symbol(:put_keyword_array_, typestr))
    #c_put_keyword_column = String(Symbol(:put_keyword_column_, typestr))

    @eval function read_keyword(table::Table, keyword::Keyword, ::Type{$T}, shape)
        value = ccall(($c_get_keyword, libcasacorewrapper), $Tc,
                      (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
        wrap_value(value)
    end

    @eval function read_keyword(table::Table, keyword::Keyword, ::Type{Array{$T}}, shape)
        ptr = ccall(($c_get_keyword_array, libcasacorewrapper), Ptr{$Tc},
                    (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
        wrap(ptr, shape)
    end

#    @eval function read_keyword(table::Table, column::String, keyword::Keyword, ::Type{$T})
#        ccall(($c_get_keyword_column, libcasacorewrapper), $T, (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}),
#              table, column, keyword)
#    end

    @eval function write_keyword!(table::Table, value::$T, keyword::Keyword)
        ccall(($c_put_keyword, libcasacorewrapper), Void,
              (Ptr{CasaCoreTable}, Ptr{Cchar}, $Tc), table, keyword, value)
        value
    end

    @eval function write_keyword!(table::Table, value::Array{$T}, keyword::Keyword)
        shape = convert(Vector{Cint}, collect(size(value)))
        ccall(($c_put_keyword_array, libcasacorewrapper), Void,
              (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{$Tc}, Ptr{Cint}, Cint),
              table, keyword, value, shape, length(shape))
        value
    end

#    @eval function write_keyword!(table::Table, value::$T, column::String, keyword::Keyword)
#        ccall(($c_put_keyword_column, libcasacorewrapper), Void,
#              (Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}, $T), table, column, keyword, value)
#        value
#    end
end

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

