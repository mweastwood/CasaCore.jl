module CasaCore

module Private
    # Do not depend on this submodule!
    export libcasacorewrapper
    const libcasacorewrapper = joinpath(Pkg.dir("CasaCore"),"deps/usr/lib/libcasacorewrapper.so")
    isfile(libcasacorewrapper) || error("Run Pkg.build(\"CasaCore\")")

    export type2str, str2type, type2enum, enum2type
    include("conversions.jl")

    export RecordField
    export RecordDesc, addfield!
    export Record, nfields
    include("containers.jl")
end

module Tables
    export Table
    export numrows, numcolumns, numkeywords
    export @kw_str

    importall ..Private
    include("tables.jl")
end

module Measures
    export Quantity, @q_str

    export ReferenceFrame
    export Measure, Epoch, Direction, Position
    export set!, measure

    importall ..Private
    import Base: show, convert
    include("quanta.jl")
    include("measures.jl")
end

end

