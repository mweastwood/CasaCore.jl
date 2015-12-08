@testset "Coordinate Conversion Tests" begin
    # test that the vectorized and non-vectorized forms of `measure`
    # give the same answer
    N = 256
    frame = ReferenceFrame()
    utc = epoch"UTC"
    dates = Epoch{utc}[Epoch(utc,Quantity(50237.29+randn(),"d")) for n = 1:N]
    tai1 = [measure(frame,date,epoch"TAI") for date in dates]
    tai2 = measure(frame,dates,epoch"TAI")
    for n = 1:N
        t1 = tai1[n]
        t2 = tai2[n]
        @test coordinate_system(t1) === coordinate_system(t2) === epoch"TAI"
        @test days(t1) == days(t2)
    end
end

