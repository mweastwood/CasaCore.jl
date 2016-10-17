@testset "common.jl" begin
    exception = CasaCoreError("this is a test")
    @test repr(exception) == "CasaCoreError: this is a test"
    @test_throws CasaCoreError throw(exception)
end

