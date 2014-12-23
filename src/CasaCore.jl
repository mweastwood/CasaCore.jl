module CasaCore

# Tables
export Table
export nrows, ncolumns
export addRows!, removeRows!
export addScalarColumn!, addArrayColumn!, removeColumn!
export getColumn, getColumn!, putColumn!
export getKeyword, putKeyword!

# Measurement Sets
export MeasurementSet
export getData,  getModelData,  getCorrectedData
export putData!, putModelData!, putCorrectedData!
export getAntenna1, getAntenna2
export putAntenna1, putAntenna2
export getUVW, getFreq, getTime

# Quanta
export Quantity, @q_str

# Measures
export ReferenceFrame
export set!
export Measure, Epoch, Direction, Position
export measure, observatory

const libcasacorewrapper = joinpath(Pkg.dir("CasaCore"),"deps/usr/lib/libcasacorewrapper.so")
isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")

import Base: show

include("conversions.jl")
include("containers.jl")
include("tables.jl")
include("measurementsets.jl")
include("quanta.jl")
include("measures.jl")

end

