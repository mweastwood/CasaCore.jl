@doc """
This type holds a pointer to the MeasuresProxy class.
I've always felt ReferenceFrame is a more appropriate name
for what this class actually does.
""" ->
type ReferenceFrame
    ptr::Ptr{Void}
end

function ReferenceFrame()
    rf = ReferenceFrame(ccall(("newMeasures",libcasacorewrapper),Ptr{Void},()))
    finalizer(rf,referenceframefinalizer)
    rf
end

function referenceframefinalizer(rf::ReferenceFrame)
    ccall(("deleteMeasures",libcasacorewrapper),Void,(Ptr{Void},),rf.ptr)
end

type Measure{T<:FloatingPoint,S<:String,N}
    measuretype::S
    system::S
    m::NTuple{N,Quantity{T,S}}
end

function Measure(record::CasaRecord)
    measuretype = record["type"]
    system = record["refer"]
    m = Quantity[]
    for i = 1:nfields(record)-2
        push!(m,Quantity(record["m$(i-1)"]))
    end
    Measure(measuretype,system,m...)
end

Measure(measuretype,system,m...) = Measure(measuretype,system,m)
Epoch(system,m1) = Measure("epoch",system,(m1,))
Direction(system,m1,m2) = Measure("direction",system,(m1,m2))
Position(system,m1,m2,m3) = Measure("position",system,(m1,m2,m3))

function CasaRecord{T,S,N}(measurement::Measure{T,S,N})
    description = CasaRecordDesc()
    addField(description,"type", TpString)
    addField(description,"refer",TpString)
    for i = 1:N
        addField(description,"m$(i-1)",TpRecord)
    end
    
    record = CasaRecord(description)
    record["type"]  = measurement.measuretype
    record["refer"] = measurement.system
    for i = 1:N
        _description = CasaRecordDesc()
        addField(_description,"value",type2enum[T])
        addField(_description,"unit", TpString)
        _record = CasaRecord(_description)
        _record["value"]  = measurement.m[i].value
        _record["unit"]   = measurement.m[i].unit
        record["m$(i-1)"] = _record
    end
    record
end

function set!(rf::ReferenceFrame,measurement::Measure)
    record = CasaRecord(measurement)
    ccall(("doframe",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Void}),
          rf.ptr,record.ptr)
end

function measure(rf::ReferenceFrame,newsystem::String,measurement::Measure)
    record = CasaRecord(measurement)
    newrecord = CasaRecord(ccall(("measure",libcasacorewrapper),
                                 Ptr{Void},(Ptr{Void},Ptr{Void},Ptr{Cchar}),
                                 rf.ptr,record.ptr,newsystem))
    Measure(newrecord)
end

function observatory(rf::ReferenceFrame,name::String)
    record = CasaRecord(ccall(("observatory",libcasacorewrapper),
                              Ptr{Void},(Ptr{Void},Ptr{Cchar}),
                              rf.ptr,name))
    Measure(record)
end

