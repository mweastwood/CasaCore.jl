let
    @test baseline"ITRF" === Measures.Types_of_Baselines.ITRF
    @test baseline"J2000" === Measures.Types_of_Baselines.J2000
end

let
    frame = ReferenceFrame()
    position = observatory("OVRO_MMA")
    time = Epoch(epoch"UTC",Quantity(50237.29,"d"))
    zenith = Direction(dir"AZEL",q"0deg",q"90deg")
    set!(frame,position)
    set!(frame,time)
    set!(frame,zenith)

    u = 1.234
    v = 5.678
    w = 0.100
    baseline = Baseline(baseline"ITRF",u,v,w)
    x,y,z = vector(baseline)
    @test coordinate_system(baseline) === baseline"ITRF"
    @test u == x
    @test v == y
    @test w == z
    @test length(baseline) ≈ sqrt(u^2+v^2+w^2)

    baseline1 = Baseline(baseline"ITRF",q"10.0m",q"0.0rad",q"0.0rad")
    baseline2 = measure(frame,baseline1,baseline"J2000")
    baseline3 = measure(frame,baseline1,baseline"ITRF")
    @test coordinate_system(baseline3) === coordinate_system(baseline1)
    @test    length(baseline3) ≈    length(baseline1)
    @test longitude(baseline3) ≈ longitude(baseline1)
    @test  latitude(baseline3) ≈  latitude(baseline1)
    @test repr(baseline1) == "(10.0 m, 0.0 m, 0.0 m)"
end

