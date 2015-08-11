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

@enum EpochRef LAST LMST GMST1 GAST UT1 UT2 UTC TAI TDT TCG TDB TCB
const IAT = TAI
const GMST = GMST1
const TT = TDT
const UT = UT1
const ET = TT

type Epoch{ref} <: Measure
    ptr::Ptr{Void}
end

function Epoch(ref::EpochRef, time::Quantity)
    epoch = ccall(("newEpoch",libcasacorewrapper), Ptr{Void},
                  (Ptr{Void},Cint), pointer(time), ref) |> Epoch{ref}
    finalizer(epoch,delete)
    epoch
end

Epoch(time) = Epoch(UTC,time)

function delete(epoch::Epoch)
    ccall(("deleteEpoch",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(epoch))
end

pointer(epoch::Epoch) = epoch.ptr
reference{ref}(::Epoch{ref}) = ref

function get(epoch::Epoch, unit::Unit)
    ccall(("getEpoch",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(epoch), pointer(unit))
end

days(epoch::Epoch) = get(epoch,Quanta.Day)
seconds(epoch::Epoch) = get(epoch,Quanta.Second)

show(io::IO, epoch::Epoch) = print(io,days(epoch)," days")

function measure(frame::ReferenceFrame,epoch::Epoch,newref::EpochRef)
    newepoch = ccall(("convertEpoch",libcasacorewrapper), Ptr{Void},
                     (Ptr{Void},Cint,Ptr{Void}),
                     pointer(epoch), newref, pointer(frame)) |> Epoch{newref}
    finalizer(newepoch,delete)
    newepoch
end

