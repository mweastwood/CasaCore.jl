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

function Table(name::String)
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

function getKeyword_string(table::Table,keyword::String,buffersize::Int=200)
    output = Array(Cchar,buffersize)
    ccall(("getKeyword_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Csize_t),
          table.ptr,keyword,output,length(output))
    bytestring(Ptr{Cchar}(output))
end

function getColumnType(table::Table,column::String)
    output = Array(Cchar,30)
    ccall(("getColumnType",libcasacorewrapper),
           Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar},Csize_t),
           table.ptr,column,output,length(output))
    str2type[bytestring(Ptr{Cchar}(output))]
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
This function reads in a column from an open table.

The type and shape of the column is determined from the
appropriate function. Depending on the data type, the
correct C function is chosen using multiple dispatch with
the function getColumn_helper!(...)
""" ->
function getColumn(table::Table,column::String)
    T = getColumnType(table,column)
    S = tuple(getColumnShape(table,column)...)
    vector = Array(T,prod(S))
    getColumn_helper!(vector,table,column)
    reshape(vector,S)
end

for typestr in ("int","double","complex")
    T = str2type[typestr]
    cfunc = "getColumn_$typestr"
    @eval function getColumn_helper!(output::Vector{$T},table::Table,column::String)
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{$T},Csize_t),
              table.ptr,column,pointer(output),length(output))
        nothing
    end
end

@doc """
This functions writes a column to an open table.
""" ->
function putColumn!(table::Table,column::String,array::Array)
    putColumn_helper(table,column,array)
    nothing
end

for typestr in ("complex",)
    T = str2type[typestr]
    cfunc = "putColumn_$typestr"
    @eval function putColumn_helper(table::Table,column::String,array::Array{$T})
        S = [size(array)...]
        ndim = length(S)
        ccall(($cfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},Ptr{$T},Ptr{Csize_t},Csize_t),
              table.ptr,column,pointer(array),pointer(S),ndim)
        nothing
    end
end

