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

# Options for opening tables
const Table_TableOption_Old          = 1
const Table_TableOption_New          = 2
const Table_TableOption_NewNoReplace = 3
const Table_TableOption_Scratch      = 4
const Table_TableOption_Update       = 5
const Table_TableOption_Delete       = 6

"""
    type Table

This type is used to interact with CasaCore tables (including
Measurement Sets).
"""
type Table
    ptr::Ptr{Void} # pointer to a casa::TableProxy instance
end

"""
    Table(name::ASCIIString)

Open and lock the CasaCore table. If no table with the given name
exists, a new table is created.
"""
function Table(name::ASCIIString)
    # Remove the "Table: " prefix, if it exists
    strippedname = replace(name,"Table: ","",1)
    if isdir(strippedname)
        table = Table(ccall(("newTable_existing",libcasacorewrapper),
                            Ptr{Void},(Ptr{Cchar},Cint),
                            pointer(strippedname),Table_TableOption_Update))
    else
        table = Table(ccall(("newTable",libcasacorewrapper),
                            Ptr{Void},(Ptr{Cchar},Ptr{Cchar},Ptr{Cchar},Cint),
                            pointer(strippedname),pointer("local"),pointer("plain"),0))
    end
    finalizer(table,delete)
    table
end

function delete(table::Table)
    ccall(("deleteTable",libcasacorewrapper),Void,(Ptr{Void},),table.ptr)
end

function flush(table::Table)
    ccall(("flush",libcasacorewrapper),Void,(Ptr{Void},Bool),table.ptr,true)
end

for f in (:iswritable,:isreadable)
    @eval function $f(table::Table)
        ccall(($(string(f)),libcasacorewrapper),Bool,(Ptr{Void},),table.ptr)
    end
end

for f in (:numrows,:numcolumns,:numkeywords)
    @eval function $f(table::Table)
        ccall(($(string(f)),libcasacorewrapper),Cint,(Ptr{Void},),table.ptr)
    end
end

@doc """
    numrows(table::Table)

Returns the number of rows in the given table.
""" numrows

@doc """
    numcolumns(table::Table)

Returns the number of columns in the given table.
""" numcolumns

@doc """
    numkeywords(table::Table)

Returns the number of keywords associated with the given table.
""" numkeywords

size(table::Table) = (numrows(table),numcolumns(table))

"""
    lock(table::Table; writelock = true, attempts = 5)

Attempt to get a lock on the given table. Errors if a lock is not
obtained after the given number of attempts.
"""
function lock(table::Table;writelock::Bool=true,attempts::Int=5)
    success = ccall(("lock",libcasacorewrapper),Bool,
                    (Ptr{Void},Bool,Cint),
                    table.ptr,writelock,attempts)
    if !success
        error("Could not get a lock on the table.")
    end
    nothing
end

"""
    unlock(table::Table)

Clear any locks obtained on the given table.
"""
function unlock(table::Table)
    ccall(("unlock",libcasacorewrapper),Void,(Ptr{Void},),table.ptr)
end

################################################################################
# Keyword Operations

immutable Keyword
    name::ASCIIString
end

macro kw_str(string)
    quote
        Keyword($string)
    end
end

getindex(table::Table,keyword::Keyword) = getKeyword(table,keyword.name)
setindex!(table::Table,value,keyword::Keyword) = putKeyword!(table,keyword.name,value)
getindex(table::Table,column::ASCIIString,keyword::Keyword) = getColumnKeyword(table,column,keyword.name)
setindex!(table::Table,value,column::ASCIIString,keyword::Keyword) = putColumnKeyword!(table,column,keyword.name,value)

function getKeywordType(table::Table,kw::ASCIIString)
    output = ccall(("getKeywordType",libcasacorewrapper),
                   Cint,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
                   table.ptr,pointer(""),pointer(kw))
    enum2type[TypeEnum(output)]
end

function getKeyword(table::Table,kw::ASCIIString)
    T = getKeywordType(table,kw)
    getKeyword(table,kw,T)
end

for T in (Bool,Int32,Float32,Float64)
    typestr = type2str[T]

    cfunc = "getKeyword_$typestr"
    @eval function getKeyword(table::Table,kw::ASCIIString,::Type{$T})
        ccall(($cfunc,libcasacorewrapper),
              $T,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
              table.ptr,pointer(""),pointer(kw))
    end

    cfunc = "putKeyword_$typestr"
    @eval function putKeyword!(table::Table,kw::ASCIIString,value::$T)
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},$T),
              table.ptr,pointer(""),pointer(kw),value)
    end
end

function getKeyword(table::Table,kw::ASCIIString,::Type{ASCIIString})
    N = ccall(("getKeyword_string_length",libcasacorewrapper),
              Int,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
              table.ptr,pointer(""),pointer(kw))
    output = Array(Cchar,N)
    ccall(("getKeyword_string",libcasacorewrapper),
          Ptr{Cchar},(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Cchar}),
          table.ptr,pointer(""),pointer(kw),pointer(output))
    chars = [Char(x) for x in output]
    ascii(chars)
end

function putKeyword!(table::Table,kw::ASCIIString,value::ASCIIString)
    ccall(("putKeyword_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Cchar}),
          table.ptr,pointer(""),pointer(kw),pointer(value))
end

function getColumnKeywordType(table::Table,column::ASCIIString,kw::ASCIIString)
    output = ccall(("getKeywordType",libcasacorewrapper),
                   Cint,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
                   table.ptr,pointer(column),pointer(kw))
    enum2type[TypeEnum(output)]
end

function getColumnKeyword(table::Table,column::ASCIIString,kw::ASCIIString)
    T = getColumnKeywordType(table,column,kw)
    getColumnKeyword(table,column,kw,T)
end

# Deal with special cases (strings)

function getColumnKeyword(table::Table,column::ASCIIString,kw::ASCIIString,::Type{ASCIIString})
    N = ccall(("getKeyword_string_length",libcasacorewrapper),
              Int,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
              table.ptr,pointer(column),pointer(kw))
    output = Array(Cchar,N)
    ccall(("getKeyword_string",libcasacorewrapper),
          Ptr{Cchar},(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Cchar}),
          table.ptr,pointer(column),pointer(kw),pointer(output))
    chars = [Char(x) for x in output]
    ascii(chars)
end

function getColumnKeyword(table::Table,column::ASCIIString,kw::ASCIIString,::Type{Vector{ASCIIString}})
    N = ccall(("getKeywordLength_string",libcasacorewrapper),
              Cint,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
              table.ptr,pointer(column),pointer(kw))
    output = Array(ASCIIString,N)
    temp   = Array(Ptr{Cchar},N)
    ccall(("getKeywordArray_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Ptr{Cchar}},Csize_t),
          table.ptr,pointer(column),pointer(kw),pointer(temp),length(temp))
    for i = 1:length(output)
        output[i] = bytestring(temp[i])
    end
    output
end

function putColumnKeyword!(table::Table,column::ASCIIString,kw::ASCIIString,value::ASCIIString)
    ccall(("putKeyword_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Cchar}),
          table.ptr,pointer(column),pointer(kw),pointer(value))
end

function putColumnKeyword!(table::Table,column::ASCIIString,kw::ASCIIString,value::Vector{ASCIIString})
    pointers = [pointer(v) for v in value]
    ccall(("putKeywordArray_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Ptr{Cchar}},Csize_t),
          table.ptr,pointer(column),pointer(kw),pointer(pointers),length(value))
end

################################################################################
# Row Operations

"""
    addRows!(table::Table, nrows::Integer)

Add the given number of rows to the table.
"""
function addRows!(table::Table,nrows::Integer)
    ccall(("addRow",libcasacorewrapper),Void,(Ptr{Void},Cint),table.ptr,nrows)
end

function removeRows!{T<:Integer}(table::Table,rows::Vector{T})
    if ccall(("canRemoveRow",libcasacorewrapper),Bool,(Ptr{Void},),table.ptr)
        rows = rows - 1 # correct for difference in indexing between C and Julia
        ccall(("removeRow",libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cint},Csize_t),
              table.ptr,pointer(rows),length(rows))
    else
        error("Rows cannot be removed from this table.")
    end
    nothing
end

################################################################################
# Column Operations

getindex(table::Table,column::ASCIIString) = getColumn(table,column)
setindex!(table::Table,value,column::ASCIIString) = putColumn!(table,column,value)

for T in (Bool,Int32,Float32,Float64,Complex64)
    typestr = type2str[T]
    cfunc_addscalarcolumn = "addScalarColumn_$typestr"
    cfunc_addarraycolumn = "addArrayColumn_$typestr"

    @eval function addScalarColumn!(table::Table,column::ASCIIString,::Type{$T})
        ccall(($cfunc_addscalarcolumn,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar}),
              table.ptr,pointer(column))
    end

    @eval function addArrayColumn!{I<:Integer}(table::Table,column::ASCIIString,::Type{$T},dimensions::Vector{I})
        dimensions_cint = convert(Vector{Cint},dimensions)
        ccall(($cfunc_addarraycolumn,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{Cint},Csize_t),
              table.ptr,pointer(column),pointer(dimensions_cint),length(dimensions))
    end
end

function removeColumn!(table::Table,column::ASCIIString)
    ccall(("removeColumn",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar}),
          table.ptr,pointer(column))
end

"""
    checkColumnExists(table::Table, column::ASCIIString)

Returns true if the column exists in the table. Otherwise
returns false.
"""
function checkColumnExists(table::Table,column::ASCIIString)
    ccall(("columnExists",libcasacorewrapper),
          Bool,(Ptr{Void},Ptr{Cchar}),
          table.ptr,pointer(column))
end

function getColumnType(table::Table,column::ASCIIString)
    output = ccall(("getColumnType",libcasacorewrapper),
                   Cint,(Ptr{Void},Ptr{Cchar}),
                   table.ptr,pointer(column))
    enum2type[TypeEnum(output)]
end

"""
    getColumnShape(table::Table, column::ASCIIString, buffersize = 4)

This function returns the shape of the column assuming that the
shape of the first cell in the column is representative of the
shape of every cell in the column.
"""
function getColumnShape(table::Table,column::ASCIIString,buffersize::Int=4)
    output = Array(Cint,buffersize)
    ccall(("getColumnShape",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cint},Csize_t),
          table.ptr,pointer(column),output,length(output))
    # The output is terminated with a negative integer (-1).
    # Numbers preceding this negative value determine the shape.
    shape = Int[]
    for i = 1:buffersize
        output[i] < 0 && break
        push!(shape,output[i])
    end
    shape
end

function getColumn(table::Table,column::ASCIIString)
    checkColumnExists(table,column) || error("Column $column does not exist.")
    T = getColumnType(table,column)
    S = getColumnShape(table,column)
    array = Array(T,S...)
    getColumn!(array,table,column)
    array
end

for T in (Bool,Int32,Float32,Float64,Complex64)
    typestr = type2str[T]

    cfunc = "getColumn_$typestr"
    @eval function getColumn!(output::Array{$T},table::Table,column::ASCIIString)
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{$T},Csize_t),
              table.ptr,pointer(column),pointer(output),length(output))
        nothing
    end

    cfunc = "putColumn_$typestr"
    @eval function putColumn!(table::Table,column::ASCIIString,array::Array{$T})
        S = [size(array)...]
        ndim = length(S)
        # Create the column if it doesn't exist
        if !checkColumnExists(table,column)
            if ndim == 1
                addScalarColumn!(table,column,$T)
            else
                addArrayColumn!(table,column,$T,S[1:end-1])
            end
        end
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{$T},Ptr{Csize_t},Csize_t),
              table.ptr,pointer(column),pointer(array),pointer(S),ndim)
    end
end

@doc "Read a column from an open table." getColumn!
@doc "Write a column to an open table." putColumn!

################################################################################
# Cell Operations

getindex(table::Table,column::ASCIIString,row::Int) = getCell(table,column,row)
setindex!(table::Table,value,column::ASCIIString,row::Int) = putCell!(table,column,row,value)

function getCell(table::Table,column::ASCIIString,row::Int)
    checkColumnExists(table,column) || error("Column $column does not exist.")
    T = getColumnType(table,column)
    S = getColumnShape(table,column)
    cell = Array(T,S[1:end-1]...)
    getCell!(cell,table,column,row)
    if length(S) == 1
        # Scalar columns have scalar cells
        # (don't return 0-dim arrays)
        return cell[1]
    end
    cell
end

for T in (Bool,Int32,Float32,Float64,Complex64)
    typestr = type2str[T]
    cfunc = "getCell_$typestr"
    @eval function getCell!(output::Array{$T},table::Table,
                            column::ASCIIString,row::Int)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Cint,Ptr{$T},Csize_t),
              table.ptr,pointer(column),row-1,pointer(output),length(output))
    end

    cfunc = "putCell_$typestr"
    @eval function putCell!(table::Table,column::ASCIIString,row::Int,array::Array{$T})
        checkColumnExists(table,column) || error("Column $column does not exist.")
        S = [size(array)...]
        ndim = length(S)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Cint,Ptr{$T},Ptr{Csize_t},Csize_t),
              table.ptr,pointer(column),row-1,pointer(array),pointer(S),ndim)
    end

    cfunc = "putCell_scalar_$typestr"
    @eval function putCell!(table::Table,column::ASCIIString,row::Int,scalar::$T)
        checkColumnExists(table,column) || error("Column $column does not exist.")
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Cint,$T),
              table.ptr,pointer(column),row-1,scalar)
    end
end

