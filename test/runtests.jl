addprocs(1) # worker used for testing Table locks
using CasaCore.Tables
using CasaCore.Measures
using Base.Test

srand(123)

@testset "CasaCore Tests" begin
    include("tables.jl")
    include("measures.jl")
end

