@doc """
Pointer to a casa::RecordDesc object.
""" ->
type CasaRecordDesc
    ptr::Ptr{Void}
    function CasaRecordDesc(ptr::Ptr{Void})
        recorddesc = new(ptr)
        finalizer(recorddesc,recorddescfinalizer)
        recorddesc
    end
end

CasaRecordDesc() = CasaRecordDesc(ccall(("createRecordDesc",libcasacorewrapper),Ptr{Void},()))
function recorddescfinalizer(recorddesc::CasaRecordDesc)
    ccall(("deleteRecordDesc",libcasacorewrapper),Void,(Ptr{Void},),recorddesc.ptr)
end

function addField(recorddesc::CasaRecordDesc,field::String,fieldtype)
    ccall(("addRecordDescField",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Cint),
          recorddesc.ptr,field,fieldtype)
end

@doc """
Pointer to a casa::Record object.
""" ->
type CasaRecord
    ptr::Ptr{Void}
    function CasaRecord(ptr::Ptr{Void})
        record = new(ptr)
        finalizer(record,recordfinalizer)
        record
    end
end

function CasaRecord(recorddesc::CasaRecordDesc)
    CasaRecord(ccall(("createRecord",libcasacorewrapper),Ptr{Void},(Ptr{Void},),recorddesc.ptr))
end
function recordfinalizer(record::CasaRecord)
    ccall(("deleteRecord",libcasacorewrapper),Void,(Ptr{Void},),record.ptr)
end

function nfields(record::CasaRecord)
    ccall(("nfields",libcasacorewrapper),
          Cuint,(Ptr{Void},),
          record.ptr)
end

setindex!(record::CasaRecord,value,field::String) = putField(record,field,value)
getindex (record::CasaRecord,      field::String) = getField(record,field)

@doc """
Put the given field value into the casa::Record object.
""" ->
function putField(record::CasaRecord,field::String,value)
    putField_helper(record,field,value)
end

@doc """
Get the field value from the casa::Record object.
""" ->
function getField(record::CasaRecord,field::String)
    N = Int(ccall(("fieldType",libcasacorewrapper),
                  Cint,(Ptr{Void},Ptr{Cchar}),
                  record.ptr,field))
    getField_helper(TpEnum{N}(),record,field)
end

for typestr in ("float","double")
    T  = str2type[typestr]
    Tp = str2enum[typestr]
    putcfunc = "putRecordField_$typestr"
    getcfunc = "getRecordField_$typestr"

    @eval function putField_helper(record::CasaRecord,field::String,value::$T)
        ccall(($putcfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},$T),
              record.ptr,field,value)
    end

    @eval function getField_helper(::TpEnum{$Tp},record::CasaRecord,field::String)
        output = ccall(($getcfunc,libcasacorewrapper),
                       $T,(Ptr{Void},Ptr{Cchar}),
                       record.ptr,field)
    end
end

function putField_helper(record::CasaRecord,field::ASCIIString,value::ASCIIString)
    ccall(("putRecordField_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
          record.ptr,field,value)
end

function getField_helper(::TpEnum{TpString},record::CasaRecord,field::ASCIIString)
    output = ccall(("getRecordField_string",libcasacorewrapper),
                   Ptr{Cchar},(Ptr{Void},Ptr{Cchar}),
                   record.ptr,field)
    bytestring(output)
end

function putField_helper(record::CasaRecord,field::ASCIIString,value::CasaRecord)
    ccall(("putRecordField_record",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Void}),
          record.ptr,field,value.ptr)
end

function getField_helper(::TpEnum{TpRecord},record::CasaRecord,field::String)
    output = ccall(("getRecordField_record",libcasacorewrapper),
                   Ptr{Void},(Ptr{Void},Ptr{Cchar}),
                   record.ptr,field)
    CasaRecord(output)
end

