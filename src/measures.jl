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

for sym in keys(measure2string)
    str = measure2string[sym]
    N = measure2dim[sym]
    T = SIUnits.SIQuantity


    @eval type $sym <: Measure
        system::ASCIIString
        m::NTuple{$N,$T}
    end

    @eval $sym(system::ASCIIString,m::$T...) = $sym(system,m)

    @eval function $sym(record::Record)
        system = record["refer"]
        m = Array($T,$N)
        for i = 1:$N
            m[i] = siquantity(record["m$(i-1)"])
        end
        $sym(system,m...)
    end

    @eval function Record(measure::$sym)
        description = RecordDesc()
        addField!(description,"type",ASCIIString)
        addField!(description,"refer",ASCIIString)
        for i = 1:$N
            addField!(description,"m$(i-1)",Record)
        end

        record = Record(description)
        record["type"]  = $str
        record["refer"] = measure.system
        for i = 1:$N
            record["m$(i-1)"] = Record(measure.m[i])
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

