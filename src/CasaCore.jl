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

__precompile__()

module CasaCore

module Tables
    export Table
    export numrows, numcolumns, numkeywords
    export lock, unlock

    export Keyword
    export @kw_str

    import Base: size, lock, unlock, getindex, setindex!

    include("common.jl")
    include("tables.jl")
end

module Measures
    export Quantity, Unit
    export @ra_str, @dec_str

    export ReferenceFrame, set!
    export Epoch, Direction, Position
    export days, seconds, length, longitude, latitude
    export coordinate_system
    export @epoch_str, @dir_str, @pos_str
    export measure
    export observatory

    import Base: pointer, length, show, get

    include("common.jl")
    include("quanta.jl")

    abstract Measure
    include("frame.jl")
    include("epoch.jl")
    include("direction.jl")
    include("position.jl")
end

end

