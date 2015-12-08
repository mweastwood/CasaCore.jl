using CasaCore.Tables
using CasaCore.Measures
if VERSION >= v"0.5-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

srand(123)

@testset "CasaCore Tests" begin
    include("tables.jl")
    include("measures.jl")
    include("epoch.jl")
    include("direction.jl")
    include("position.jl")
    include("baseline.jl")
    include("conversions.jl")
end

