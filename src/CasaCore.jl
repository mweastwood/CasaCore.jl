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

module CasaCore

module Private
    # Do not depend on this submodule!
    export libcasacorewrapper
    const libcasacorewrapper = joinpath(dirname(@__FILE__),"../deps/libcasacorewrapper.so")
    isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")

    export type2str, str2type, type2enum, enum2type
    include("conversions.jl")

    export RecordField
    export RecordDesc, addField!
    export Record, nfields
    include("containers.jl")
end

module Tables
    export Table
    export numrows, numcolumns, numkeywords
    export @kw_str

    importall ..Private
    import Base: close
    include("tables.jl")
end

module Measures
    export  ra_str,  @ra_str
    export dec_str, @dec_str

    export ReferenceFrame
    export Measure, Epoch, Direction, Position
    export set!, measure

    export source
    export observatory

    importall ..Private
    import Base: show, convert
    using SIUnits
    include("quanta.jl")
    include("measures.jl")

    function __init__()
        Base.rehash!(si2str)
    end
end

end

