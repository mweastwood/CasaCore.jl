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

@doc """
The Table type simply contains a pointer to an instance of the
casa::TableProxy class.
""" ->
type Table
    ptr::Ptr{Void}
end

function Table(name::ASCIIString)
    # Remove the "Table: " prefix, if it exists
    strippedname = replace(name,"Table: ","",1)
    if isdir(strippedname)
        table = Table(ccall(("newTable_existing",libcasacorewrapper),
                            Ptr{Void},(Ptr{Cchar},Cint),
                            strippedname,Table_TableOption_Update))
    else
        table = Table(ccall(("newTable",libcasacorewrapper),
                            Ptr{Void},(Ptr{Cchar},Ptr{Cchar},Ptr{Cchar},Cint),
                            strippedname,"local","plain",0))
    end
    finalizer(table,close)
    table
end

@doc """
Call the table destructor.
""" ->
function close(table::Table)
    ccall(("deleteTable",libcasacorewrapper),Void,(Ptr{Void},),table.ptr)
end

function flush(table::Table)
    ccall(("flush",libcasacorewrapper),Void,(Ptr{Void},Bool),table.ptr,true)
end

for f in (:isWritable,:isReadable)
    @eval function $f(table::Table)
        ccall(($(string(f)),libcasacorewrapper),Bool,(Ptr{Void},),table.ptr)
    end
end

for f in (:numrows,:numcolumns,:numkeywords)
    @eval function $f(table::Table)
        ccall(($(string(f)),libcasacorewrapper),Cint,(Ptr{Void},),table.ptr)
    end
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
                   table.ptr,"",kw)
    enum2type[output]
end

function getKeyword(table::Table,kw::ASCIIString)
    T = getKeywordType(table,kw)
    getKeyword(table,kw,T)
end

function getKeyword(table::Table,kw::ASCIIString,::Type{ASCIIString})
    output = ccall(("getKeyword_string",libcasacorewrapper),
                   Ptr{Cchar},(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
                   table.ptr,"",kw)
    bytestring(output)::ASCIIString
end

function putKeyword!(table::Table,kw::ASCIIString,value::ASCIIString)
    ccall(("putKeyword_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Cchar}),
          table.ptr,"",kw,value)
end

function getColumnKeywordType(table::Table,column::ASCIIString,kw::ASCIIString)
    output = ccall(("getKeywordType",libcasacorewrapper),
                   Cint,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
                   table.ptr,column,kw)
    enum2type[output]
end

function getColumnKeyword(table::Table,column::ASCIIString,kw::ASCIIString)
    T = getColumnKeywordType(table,column,kw)
    getColumnKeyword(table,column,kw,T)
end

# Deal with special cases (strings and records)

function getColumnKeyword(table::Table,column::ASCIIString,kw::ASCIIString,::Type{ASCIIString})
    output = ccall(("getKeyword_string",libcasacorewrapper),
                   Ptr{Cchar},(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
                   table.ptr,column,kw)
    bytestring(output)::ASCIIString
end

function getColumnKeyword(table::Table,column::ASCIIString,kw::ASCIIString,::Type{Array{ASCIIString}})
    N = ccall(("getKeywordLength_string",libcasacorewrapper),
              Cint,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
              table.ptr,column,kw)
    output = Array(ASCIIString,N)
    temp   = Array(Ptr{Cchar},N)
    ccall(("getKeywordArray_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Ptr{Cchar}},Csize_t),
          table.ptr,column,kw,pointer(temp),length(temp))
    for i = 1:length(output)
        output[i] = bytestring(temp[i])
    end
    output
end

function putColumnKeyword!(table::Table,column::ASCIIString,kw::ASCIIString,value::ASCIIString)
    ccall(("putKeyword_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Cchar}),
          table.ptr,column,kw,value)
end

function putColumnKeyword!(table::Table,column::ASCIIString,kw::ASCIIString,value::Array{ASCIIString})
    ccall(("putKeywordArray_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Ptr{Ptr{Cchar}},Csize_t),
          table.ptr,column,kw,value,length(value))
end

################################################################################
# Row Operations

function addRows!{T<:Integer}(table::Table,nrows::T)
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

for T in (Int32,Float32,Float64,Complex64)
    typestr = type2str[T]
    cfunc_addscalarcolumn = "addScalarColumn_$typestr"
    cfunc_addarraycolumn = "addArrayColumn_$typestr"

    @eval function addScalarColumn!(table::Table,column::ASCIIString,::Type{$T})
        ccall(($cfunc_addscalarcolumn,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar}),
              table.ptr,column)
    end

    @eval function addArrayColumn!{I<:Integer}(table::Table,column::ASCIIString,::Type{$T},dimensions::Vector{I})
        dimensions_cint = convert(Vector{Cint},dimensions)
        ccall(($cfunc_addarraycolumn,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{Cint},Csize_t),
              table.ptr,column,pointer(dimensions_cint),length(dimensions))
    end
end

function removeColumn!(table::Table,column::ASCIIString)
    ccall(("removeColumn",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar}),
          table.ptr,column)
end

@doc """
Returns true if the column exists in the table. Otherwise
returns false.
""" ->
function checkColumnExists(table::Table,column::ASCIIString)
    ccall(("columnExists",libcasacorewrapper),
          Bool,(Ptr{Void},Ptr{Cchar}),
          table.ptr,column)
end

function getColumnType(table::Table,column::ASCIIString)
    output = ccall(("getColumnType",libcasacorewrapper),
                   Ptr{Cchar},(Ptr{Void},Ptr{Cchar}),
                   table.ptr,column)
    str2type[bytestring(output)::ASCIIString]
end

@doc """
This function returns the shape of the column assuming that the
shape of the first cell in the column is representative of the
shape of every cell in the column. This is not a safe assumption
in general, but works for LWA datasets.
""" ->
function getColumnShape(table::Table,column::ASCIIString,buffersize::Int=4)
    output = Array(Cint,buffersize)
    ccall(("getColumnShape",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cint},Csize_t),
          table.ptr,column,output,length(output))
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

for T in (Int32,Float32,Float64,Complex64)
    typestr = type2str[T]

    cfunc = "getColumn_$typestr"
    @eval function getColumn!(output::Array{$T},table::Table,column::ASCIIString)
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{$T},Csize_t),
              table.ptr,column,pointer(output),length(output))
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
              table.ptr,column,pointer(array),pointer(S),ndim)
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

for T in (Int32,Float32,Float64,Complex64)
    typestr = type2str[T]
    cfunc = "getCell_$typestr"
    @eval function getCell!(output::Array{$T},table::Table,
                            column::ASCIIString,row::Int)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Cint,Ptr{$T},Csize_t),
              table.ptr,column,row-1,pointer(output),length(output))
    end

    cfunc = "putCell_$typestr"
    @eval function putCell!(table::Table,column::ASCIIString,row::Int,array::Array{$T})
        checkColumnExists(table,column) || error("Column $column does not exist.")
        S = [size(array)...]
        ndim = length(S)
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Cint,Ptr{$T},Ptr{Csize_t},Csize_t),
              table.ptr,column,row-1,pointer(array),pointer(S),ndim)
    end

    cfunc = "putCell_scalar_$typestr"
    @eval function putCell!(table::Table,column::ASCIIString,row::Int,scalar::$T)
        checkColumnExists(table,column) || error("Column $column does not exist.")
        # Subtract 1 from the row number to convert to a 0-based indexing scheme
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Cint,$T),
              table.ptr,column,row-1,scalar)
    end
end

