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

module Baselines
    @enum(System,
          J2000, JMEAN, JTRUE, APP, B1950, B1950_VLA, BMEAN, BTRUE,
          GALACTIC, HADEC, AZEL, AZELSW, AZELGEO, AZELSWGEO, JNAT,
          ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF, TOPO, ICRS)
    const AZELNE = AZEL
    const AZELNEGEO = AZELGEO
end

macro baseline_str(sys)
    eval(current_module(),:(Measures.Baselines.$(symbol(sys))))
end

@measure :Baseline 3

@doc doc"""
    type Baseline{sys} <: Measure

This type represents a baseline (ie. the vector displacement
from one antenna to another antenna). The type parameter `sys`
defines the coordinate system.

    Baseline(sys, length::Quantity, longitude::Quantity, latitude::Quantity)

Instantiate a baseline from the given coordinate system, length, longitude,
and latitude.

    Baseline(sys, x::Float64, y::Float64, z::Float64)

Construct a baseline from the Cartesian vector $(x,y,z)$ where each
coordinate has units of meters.
""" Baseline

@add_vector_like_methods :Baseline

function show(io::IO, baseline::Baseline)
    u,v,w = vector(baseline)
    print(io,"(",u," m, ",v," m, ",w," m)")
end

