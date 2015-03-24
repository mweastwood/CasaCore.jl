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

function addField!{T}(recorddesc::RecordDesc,field::ASCIIString,::Type{T})
    tpenum = type2enum[T]::Int
    ccall(("addRecordDescField",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Cint),
          recorddesc.ptr,pointer(field),tpenum)
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
enum2type[TpRecord] = Record

function nfields(record::Record)
    ccall(("nfields",libcasacorewrapper),
          Cuint,(Ptr{Void},),
          record.ptr)
end

getindex (record::Record,      field::ASCIIString) = getField(record,field)
setindex!(record::Record,value,field::ASCIIString) = putField!(record,field,value)

function getFieldType(record::Record,field::ASCIIString)
    output = ccall(("fieldType",libcasacorewrapper),
                   Cint,(Ptr{Void},Ptr{Cchar}),
                   record.ptr,pointer(field))
    enum2type[output]
end

function getField(record::Record,field::ASCIIString)
    T = getFieldType(record,field)
    getField(record,field,T)
end

for T in (Float32,Float64)
    typestr = type2str[T]
    tpenum  = type2enum[T]
    getcfunc = "getRecordField_$typestr"
    putcfunc = "putRecordField_$typestr"

    @eval function getField(record::Record,field::ASCIIString,::Type{$T})
        output = ccall(($getcfunc,libcasacorewrapper),
                       $T,(Ptr{Void},Ptr{Cchar}),
                       record.ptr,pointer(field))
    end

    @eval function putField!(record::Record,field::ASCIIString,value::$T)
        ccall(($putcfunc,libcasacorewrapper),
              Void,(Ptr{Void},Ptr{Cchar},$T),
              record.ptr,pointer(field),value)
    end
end

@doc "Get the field value from the casa::Record object." getField
@doc "Put the given field value into the casa::Record object." putField!

# Deal with special cases (strings and sub-records)

function getField(record::Record,field::ASCIIString,::Type{ASCIIString})
    output = ccall(("getRecordField_string",libcasacorewrapper),
                   Ptr{Cchar},(Ptr{Void},Ptr{Cchar}),
                   record.ptr,pointer(field))
    bytestring(output)
end

function putField!(record::Record,field::ASCIIString,value::ASCIIString)
    ccall(("putRecordField_string",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
          record.ptr,pointer(field),pointer(value))
end

function getField(record::Record,field::ASCIIString,::Type{Record})
    output = ccall(("getRecordField_record",libcasacorewrapper),
                   Ptr{Void},(Ptr{Void},Ptr{Cchar}),
                   record.ptr,pointer(field))
    Record(output)
end

function putField!(record::Record,field::ASCIIString,value::Record)
    ccall(("putRecordField_record",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Cchar},Ptr{Void}),
          record.ptr,pointer(field),value.ptr)
end

