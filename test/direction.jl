let
    @test dir"J2000" === Measures.Types_of_Directions.J2000
    @test dir"AZEL" === Measures.Types_of_Directions.AZEL
end

let
    frame = ReferenceFrame()
    position = observatory("OVRO_MMA")
    time = Epoch(epoch"UTC",Quantity(50237.29,"d"))
    set!(frame,position)
    set!(frame,time)

    dir1  = Direction(dir"AZEL",q"1.0rad",q"1.0rad")
    j2000 = measure(frame,dir1,dir"J2000")
    dir2  = measure(frame,j2000,dir"AZEL")

    @test coordinate_system(dir1)  === dir"AZEL"
    @test coordinate_system(j2000) === dir"J2000"
    @test coordinate_system(dir2)  === dir"AZEL"
    @test longitude(dir1) ≈ longitude(dir2)
    @test  latitude(dir1) ≈  latitude(dir2)

    dir1 = Direction(dir"J2000",q"19h59m28.35663s",q"+40d44m02.0970s")
    azel = measure(frame,dir1,dir"AZEL")
    dir2 = measure(frame,azel,dir"J2000")

    @test coordinate_system(dir1) === dir"J2000"
    @test coordinate_system(azel) === dir"AZEL"
    @test coordinate_system(dir2) === dir"J2000"
    @test longitude(dir1) ≈ longitude(dir2)
    @test  latitude(dir1) ≈  latitude(dir2)

    inradians = longitude(dir1,"rad")
    indegrees = longitude(dir1,"deg")
    @test rad2deg(inradians) ≈ indegrees
    inradians = latitude(dir1,"rad")
    indegrees = latitude(dir1,"deg")
    @test rad2deg(inradians) ≈ indegrees

    dir1 = Direction(dir"J2000",q"19h59m28.35663s",q"+40d44m02.0970s")
    x,y,z = vector(dir1)
    dir2 = Direction(dir"J2000",x,y,z)
    @test coordinate_system(dir1) === coordinate_system(dir2)
    @test longitude(dir1) ≈ longitude(dir2)
    @test  latitude(dir1) ≈  latitude(dir2)

    dir = Direction(dir"SUN")
    @test coordinate_system(dir) === dir"SUN"
    @test longitude(dir,"rad") ≈ 0.0
    @test  latitude(dir,"rad") ≈ 0.0

    dir = Direction(dir"J2000",q"0.0deg",q"2.0deg")
    @test repr(dir) == "(0.0 deg, 2.0 deg)"
end

