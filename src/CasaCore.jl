module CasaCore

# Tables
export Table
export getColumn, putColumn

# Measures
export ReferenceFrame
export set!
export Measure,Quantity
export measure,observatory

# TODO: Check to make sure this file exists
const libcasacorewrapper = "../deps/usr/lib/libcasacorewrapper.so"

include("conversions.jl")
include("containers.jl")
include("tables.jl")
include("measures.jl")

end

