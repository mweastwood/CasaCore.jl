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

abstract Measure

const measure2string = Dict(:Epoch     => "epoch",
                            :Direction => "direction",
                            :Position  => "position")

const measure2dim = Dict(:Epoch     => 1,
                         :Direction => 2,
                         :Position  => 3)

const recordtype  = RecordField(ASCIIString,"type")
const recordrefer = RecordField(ASCIIString,"refer")
recordm(n) = RecordField(Record,"m$(n-1)")

for T in keys(measure2string)
    str = measure2string[T]
    N   = measure2dim[T]

    @eval type $T <: Measure
        system::ASCIIString
        m::NTuple{$N,Quantity}
    end

    @eval $T(system::ASCIIString,m::Quantity...) = $T(system,m)

    @eval function $T(record::Record)
        system = record[recordrefer]
        m = Array(Quantity,$N)
        for i = 1:$N
            m[i] = Quantity(record[recordm(i)])
        end
        $T(system,m...)
    end

    @eval function Record(measure::$T)
        description = RecordDesc()
        addfield!(description,recordtype)
        addfield!(description,recordrefer)
        for i = 1:$N
            addfield!(description,recordm(i))
        end

        record = Record(description)
        record[recordtype]  = $str
        record[recordrefer] = measure.system
        for i = 1:$N
            record[recordm(i)] = Record(measure.m[i])
        end
        record
    end
end

function set!(rf::ReferenceFrame,measure::Measure)
    record = Record(measure)
    ccall(("doframe",libcasacorewrapper),
          Void,(Ptr{Void},Ptr{Void}),
          rf.ptr,record.ptr)
end

function measure{T<:Measure}(rf::ReferenceFrame,measure::T,newsystem::String)
    record = Record(measure)
    newrecord = Record(ccall(("measure",libcasacorewrapper),
                             Ptr{Void},(Ptr{Void},Ptr{Void},Ptr{Cchar}),
                             rf.ptr,record.ptr,newsystem))
    T(newrecord)
end

function observatory(rf::ReferenceFrame,name::String)
    record = Record(ccall(("observatory",libcasacorewrapper),
                          Ptr{Void},(Ptr{Void},Ptr{Cchar}),
                          rf.ptr,name))
    Position(record)
end

