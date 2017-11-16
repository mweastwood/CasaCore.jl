# Copyright (c) 2015-2017 Michael Eastwood
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
    eval(current_module(),:(Measures.Baselines.$(Symbol(sys))))
end

"""
    Baseline <: Measure

This type represents the location of one antenna relative to another antenna.
"""
struct Baseline <: Measure
    sys :: Baselines.System
    x :: Float64 # measured in meters
    y :: Float64 # measured in meters
    z :: Float64 # measured in meters
end

units(::Type{Baseline}) = u"m"

function Base.show(io::IO, baseline::Baseline)
    str = @sprintf("%.3f meters, %.3f meters, %.3f meters", baseline.x, baseline.y, baseline.z)
    print(io, str)
end

