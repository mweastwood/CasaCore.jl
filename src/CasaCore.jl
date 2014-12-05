module CasaCore

export Table
export getColumn, putColumn

# The location of the shared library
const libwrapper = "./libcasacorewrapper.so"

include("conversions.jl")
include("containers.jl")
include("tables.jl")
include("measures.jl")

end

