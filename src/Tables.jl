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

"The `Tables` module is used to interact with CasaCore tables."
module Tables

export CasaCoreTablesError
export Table
export @kw_str

const libcasacorewrapper = normpath(joinpath(@__DIR__, "..", "deps", "src",
                                             "libcasacorewrapper.so"))

function __init__()
    isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")
end

struct CasaCoreTablesError <: Exception
    msg :: String
end
Base.show(io::IO, err::CasaCoreTablesError) = print(io, "CasaCoreTablesError: ", err.msg)
err(msg) = throw(CasaCoreTablesError(msg))

include("tables/types.jl")
include("tables/tables.jl")
include("tables/rows.jl")
include("tables/columns.jl")
include("tables/cells.jl")
include("tables/keywords.jl")

#"""
#    Tables.lock(table::Table; writelock = true, attempts = 5)
#
#Attempt to get a lock on the given table. Throws an `ErrorException` if a lock is not obtained after
#the given number of attempts.
#"""
#function lock(table::Table; writelock::Bool=true, attempts::Int=5)
#    success = ccall(("lock", libcasacorewrapper), Bool,
#                    (Ptr{Void}, Bool, Cint), table, writelock, attempts)
#    success || error("Could not get a lock on the table.")
#    nothing
#end
#
#"""
#    Tables.unlock(table::Table)
#
#Clear any locks obtained on the given table.
#"""
#function Base.unlock(table::Table)
#    ccall(("unlock", libcasacorewrapper), Void, (Ptr{Void},), table)
#end

end

