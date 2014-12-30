immutable RecordField{T}
    name::ASCIIString
end
RecordField(T::Type,name::ASCIIString) = RecordField{T}(name)

@doc """
Pointer to a casa::RecordDesc object.
""" ->
type RecordDesc
    ptr::Ptr{Void}
    function RecordDesc(ptr::Ptr{Void})
        recorddesc = new(ptr)
        finalizer(recorddesc,recorddescfinalizer)
        recorddesc
    end
end

RecordDesc() = RecordDesc(ccall(("createRecordDesc",libcasacorewrapper),Ptr{Void},()))
function recorddescfinalizer(recorddesc::RecordDesc)
    ccall(("deleteRecordDesc",libcasacorewrapper),Void,(Ptr{Void},),recorddesc.ptr)
end

function addfield!{T}(recorddesc::RecordDesc,field::RecordField{T})
    tpenum = type2enum[T]
    ccall(("addRecordDescField",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Cint),
          recorddesc.ptr,field.name,tpenum)
end

@doc """
Pointer to a casa::Record object.
""" ->
type Record
    ptr::Ptr{Void}
    function Record(ptr::Ptr{Void})
        record = new(ptr)
        finalizer(record,recordfinalizer)
        record
    end
end

function Record(recorddesc::RecordDesc)
    Record(ccall(("createRecord",libcasacorewrapper),Ptr{Void},(Ptr{Void},),recorddesc.ptr))
end
function recordfinalizer(record::Record)
    ccall(("deleteRecord",libcasacorewrapper),Void,(Ptr{Void},),record.ptr)
end

# Add Record to the type dictionairy.
# (this can only be done after the type is defined)
type2enum[Record] = TpRecord

function nfields(record::Record)
    ccall(("nfields",libcasacorewrapper),
          Cuint,(Ptr{Void},),
          record.ptr)
end

setindex!(record::Record,value,field::RecordField) = putfield!(record,field,value)
getindex (record::Record,      field::RecordField) = getfield(record,field)

for typestr in ("float","double")
    T = str2type[typestr]
    tpenum = type2enum[T]
    putcfunc = "putRecordField_$typestr"
    getcfunc = "getRecordField_$typestr"

    @eval function putfield!(record::Record,field::RecordField{$T},value::$T)
        ccall(($putcfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},$T),
              record.ptr,field.name,value)
    end

    @eval function getfield(record::Record,field::RecordField{$T})
        output = ccall(($getcfunc,libcasacorewrapper),
                       $T,(Ptr{Void},Ptr{Cchar}),
                       record.ptr,field.name)
    end
end

@doc "Put the given field value into the casa::Record object." putfield!
@doc "Get the field value from the casa::Record object." getfield

# Deal with special cases (strings and sub-records)

function putfield!(record::Record,field::RecordField{ASCIIString},value::ASCIIString)
    ccall(("putRecordField_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
          record.ptr,field.name,value)
end

function getfield(record::Record,field::RecordField{ASCIIString})
    output = ccall(("getRecordField_string",libcasacorewrapper),
                   Ptr{Cchar},(Ptr{Void},Ptr{Cchar}),
                   record.ptr,field.name)
    bytestring(output)
end

function putfield!(record::Record,field::RecordField{Record},value::Record)
    ccall(("putRecordField_record",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Void}),
          record.ptr,field.name,value.ptr)
end

function getfield(record::Record,field::RecordField{Record})
    output = ccall(("getRecordField_record",libcasacorewrapper),
                   Ptr{Void},(Ptr{Void},Ptr{Cchar}),
                   record.ptr,field.name)
    Record(output)
end

