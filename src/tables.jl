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
    if isdir(name)
        table = Table(ccall(("newTable_existing",libcasacorewrapper),
                            Ptr{Void},(Ptr{Cchar},Cint),
                            name,Table_TableOption_Update))
    else
        table = Table(ccall(("newTable",libcasacorewrapper),
                            Ptr{Void},(Ptr{Cchar},Ptr{Cchar},Ptr{Cchar},Cint),
                            name,"local","plain",0))
    end
    finalizer(table,tablefinalizer)
    table
end

@doc """
Call the table destructor.
""" ->
function tablefinalizer(table::Table)
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

for f in (:nrows,:ncolumns)
    @eval function $f(table::Table)
        ccall(($(string(f)),libcasacorewrapper),Cint,(Ptr{Void},),table.ptr)
    end
end

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

function addScalarColumn!(table::Table,name::AbstractString,typestring::AbstractString)
    ccall(("addScalarColumn",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Cint),
          table.ptr,name,str2enum[typestring])
end

function addArrayColumn!{T<:Integer}(table::Table,name::AbstractString,typestring::AbstractString,
                                     dimensions::Vector{T})
    dimensions_cint = convert(Vector{Cint},dimensions)
    ccall(("addArrayColumn",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Cint,Ptr{Cint},Csize_t),
          table.ptr,name,str2enum[typestring],pointer(dimensions_cint),length(dimensions))
end

function removeColumn!(table::Table,name::AbstractString)
    ccall(("removeColumn",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar}),
          table.ptr,name)
end

function changeColumnStorageManager!(table::Table)
    ccall(("changeColumnStorageManager",libcasacorewrapper),Void,(Ptr{Void},),table.ptr)
end

function nKeywords(table::Table)
    ccall(("nKeywords",libcasacorewrapper),Cuint,(Ptr{Void},),table.ptr)
end

function getKeyword(table::Table,keyword::ASCIIString,::Type{ASCIIString})
    output = ccall(("getKeyword_string",libcasacorewrapper),
                   Ptr{Cchar},(Ptr{Void},Ptr{Cchar}),
                   table.ptr,keyword)
    bytestring(output)::ASCIIString
end

function putKeyword!(table::Table,keyword::ASCIIString,keywordvalue::ASCIIString)
    ccall(("putKeyword_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
          table.ptr,keyword,keywordvalue)
end

################################################################################
# getColumn

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
function getColumnShape(table::Table,column::String,buffersize::Int=4)
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

@doc """
Read a column from an open table.

Note that this function is not type stable (the type
and shape of the column is not known until run time).
If you need type stability, use getColumn!
""" ->
function getColumn(table::Table,column::String)
    T = getColumnType(table,column)
    S = getColumnShape(table,column)
    array = Array(T,S...)
    getColumn!(array,table,column)
    array
end

for typestr in ("int","float","double","complex")
    T = str2type[typestr]
    cfunc = "getColumn_$typestr"
    @eval function getColumn!(output::Array{$T},table::Table,column::String)
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{$T},Csize_t),
              table.ptr,column,pointer(output),length(output))
        nothing
    end
end
@doc "Read a column from an open table." getColumn!

################################################################################
# putColumn!

for typestr in ("int","float","double","complex")
    T = str2type[typestr]
    cfunc = "putColumn_$typestr"
    @eval function putColumn!(table::Table,column::String,array::Array{$T})
        S = [size(array)...]
        ndim = length(S)
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{$T},Ptr{Csize_t},Csize_t),
              table.ptr,column,pointer(array),pointer(S),ndim)
        nothing
    end
end
@doc "Write a column to an open table." putColumn!

