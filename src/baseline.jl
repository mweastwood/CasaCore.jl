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

module Types_of_Baselines
    @enum(System,
          J2000, JMEAN, JTRUE, APP, B1950, B1950_VLA, BMEAN, BTRUE,
          GALACTIC, HADEC, AZEL, AZELSW, AZELGEO, AZELSWGEO, JNAT,
          ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF, TOPO, ICRS)
    const AZELNE = AZEL
    const AZELNEGEO = AZELGEO
end

macro baseline_str(sys)
    eval(current_module(),:(Measures.Types_of_Baselines.$(symbol(sys))))
end

"""
    type Baseline{sys} <: Measure

This type represents a baseline (ie. the vector displacement
from one antenna to another antenna). The type parameter `sys`
defines the coordinate system.
"""
type Baseline{sys} <: Measure
    ptr::Ptr{Void} # pointer fo a casa::MBaseline instance
end

"""
    Baseline(sys, length::Quantity, longitude::Quantity, latitude::Quantity)

Instantiate a baseline from the given coordinate system, length, longitude,
and latitude.
"""
function Baseline(sys::Types_of_Baselines.System,
                  length::Quantity, longitude::Quantity, latitude::Quantity)
    baseline = ccall(("newBaseline",libcasacorewrapper), Ptr{Void},
                     (Ptr{Void},Ptr{Void},Ptr{Void},Cint),
                     pointer(length), pointer(longitude), pointer(latitude), sys) |> Baseline{sys}
    finalizer(baseline,delete)
    baseline
end

function from_xyz_in_meters(sys::Types_of_Baselines.System,
                            x::Float64,y::Float64,z::Float64)
    baseline = ccall(("newBaselineXYZ",libcasacorewrapper), Ptr{Void},
                     (Cdouble,Cdouble,Cdouble,Cint), x, y, z, sys) |> Baseline{sys}
    finalizer(baseline,delete)
    baseline
end

function delete(baseline::Baseline)
    ccall(("deleteBaseline",libcasacorewrapper), Void,
          (Ptr{Void},), pointer(baseline))
end

pointer(baseline::Baseline) = baseline.ptr
coordinate_system{sys}(::Baseline{sys}) = sys

function length(baseline::Baseline, unit::Unit = Unit("m"))
    ccall(("getBaselineLength",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(baseline), pointer(unit))
end

function longitude(baseline::Baseline, unit::Unit = Unit("rad"))
    ccall(("getBaselineLongitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(baseline), pointer(unit))
end

function latitude(baseline::Baseline, unit::Unit = Unit("rad"))
    ccall(("getBaselineLatitude",libcasacorewrapper), Cdouble,
          (Ptr{Void},Ptr{Void}), pointer(baseline), pointer(unit))
end

function xyz_in_meters(baseline::Baseline)
    x = Ref{Cdouble}(0)
    y = Ref{Cdouble}(0)
    z = Ref{Cdouble}(0)
    ccall(("getBaselineXYZ",libcasacorewrapper), Void,
          (Ptr{Void},Ref{Cdouble},Ref{Cdouble},Ref{Cdouble}),
          pointer(baseline), x, y, z)
    x[],y[],z[]
end

function show(io::IO, baseline::Baseline)
    u,v,w = xyz_in_meters(baseline)
    print(io,"(",u," m, ",v," m, ",w," m)")
end

function set!(frame::ReferenceFrame,baseline::Baseline)
    ccall(("setBaseline",libcasacorewrapper), Void,
          (Ptr{Void},Ptr{Void}), pointer(frame), pointer(baseline))
end

"""
    measure(frame::ReferenceFrame, baseline::Baseline, newsys)

Convert the given baseline to the new coordinate system specified
by `newsys`. The reference frame must have enough information
to attached to it with `set!` for the conversion to be made
from the old coordinate system to the new.
"""
function measure(frame::ReferenceFrame,
                 baseline::Baseline,
                 newsys::Types_of_Baselines.System)
    newbaseline = ccall(("convertBaseline",libcasacorewrapper), Ptr{Void},
                        (Ptr{Void},Cint,Ptr{Void}),
                        pointer(baseline), newsys, pointer(frame)) |> Baseline{newsys}
    finalizer(newbaseline,delete)
    newbaseline
end

