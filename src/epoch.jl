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

module Types_of_Epochs
    @enum(System, LAST, LMST, GMST1, GAST, UT1, UT2, UTC, TAI, TDT, TCG, TDB, TCB)
    const IAT = TAI
    const GMST = GMST1
    const TT = TDT
    const UT = UT1
    const ET = TT
end

macro epoch_str(sys)
    eval(current_module(),:(Measures.Types_of_Epochs.$(symbol(sys))))
end

"""
    type Epoch{sys} <: Measure

This type represents an instance in time (ie. an epoch). The type
parameter `sys` defines the coordinate system.
"""
type Epoch{sys} <: Measure
    ptr::Ptr{Void} # pointer to a casa::MEpoch instance
end

"""
    Epoch(sys, time::Quantity)

Instantiate an epoch from the given coordinate system and time.
"""
function Epoch(sys::Types_of_Epochs.System, time::Quantity)
    epoch = ccall(("newEpoch",libcasacorewrapper), Ptr{Void},
                  (Ptr{Void},Cint), pointer(time), sys) |> Epoch{sys}
    finalizer(epoch,delete)
    epoch
end

function delete(epoch::Epoch)
    ccall(("deleteEpoch",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(epoch))
end

pointer(epoch::Epoch) = epoch.ptr
coordinate_system{sys}(::Epoch{sys}) = sys

function get(epoch::Epoch, unit::Unit)
    ccall(("getEpoch",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(epoch), pointer(unit))
end

days(epoch::Epoch) = get(epoch,Unit("d"))
seconds(epoch::Epoch) = get(epoch,Unit("s"))

show(io::IO, epoch::Epoch) = print(io,days(epoch)," days")

function set!(frame::ReferenceFrame,epoch::Epoch)
    ccall(("setEpoch",libcasacorewrapper), Void,
          (Ptr{Void},Ptr{Void}), pointer(frame), pointer(epoch))
end

"""
    measure(frame::ReferenceFrame, epoch::Epoch, newsys)

Convert the given epoch to the new coordinate system specified
by `newsys`. The reference frame must have enough information
to attached to it with `set!` for the conversion to be made
from the old coordinate system to the new.
"""
function measure(frame::ReferenceFrame,
                 epoch::Epoch,
                 newsys::Types_of_Epochs.System)
    newepoch = ccall(("convertEpoch",libcasacorewrapper), Ptr{Void},
                     (Ptr{Void},Cint,Ptr{Void}),
                     pointer(epoch), newsys, pointer(frame)) |> Epoch{newsys}
    finalizer(newepoch,delete)
    newepoch
end

