addprocs(1) # worker used for testing Table locks
using CasaCore.Tables
using CasaCore.Measures
using Unitful
using Base.Test

srand(123)

@testset "CasaCore Tests" begin
    include("common.jl")
    include("tables.jl")
    include("measures.jl")
end

