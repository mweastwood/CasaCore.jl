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

"The `MeasurementSets` module is used to interact with CasaCore measurement sets."
module MeasurementSets

using ..Tables

const libcasacorewrapper = normpath(joinpath(@__DIR__, "..", "deps", "src",
                                             "libcasacorewrapper.so"))

function __init__()
    isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")
end

include("measurement-sets/measurement-sets.jl")

end

