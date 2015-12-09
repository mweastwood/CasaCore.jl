@testset "Measures Tests" begin
    @test sexagesimal("12h34m56.78s") ≈ π/12.*(12.+34/60.+56.78/3600)
    @test sexagesimal("12h34m56s")    ≈ π/12.*(12.+34/60.+56./3600)
    @test sexagesimal("12h34.56m")    ≈ π/12.*(12.+34.56/60.)
    @test sexagesimal("12h34m")       ≈ π/12.*(12.+34./60.)
    @test sexagesimal("12.34h")       ≈ π/12.*(12.34)
    @test sexagesimal("12h")          ≈ π/12.*(12.)

    @test sexagesimal("12d34m56.78s")  ≈ π/180.*(12.+34/60.+56.78/3600)
    @test sexagesimal("12d34m56s")     ≈ π/180.*(12.+34/60.+56./3600)
    @test sexagesimal("12d34.56m")     ≈ π/180.*(12.+34.56/60.)
    @test sexagesimal("12d34m")        ≈ π/180.*(12.+34./60.)
    @test sexagesimal("12.34d")        ≈ π/180.*(12.34)
    @test sexagesimal("12d")           ≈ π/180.*(12.)
    @test sexagesimal("+12d34m56.78s") ≈ π/180.*(12.+34/60.+56.78/3600)
    @test sexagesimal("+12d34m56s")    ≈ π/180.*(12.+34/60.+56./3600)
    @test sexagesimal("+12d34.56m")    ≈ π/180.*(12.+34.56/60.)
    @test sexagesimal("+12d34m")       ≈ π/180.*(12.+34./60.)
    @test sexagesimal("+12.34d")       ≈ π/180.*(12.34)
    @test sexagesimal("+12d")          ≈ π/180.*(12.)
    @test sexagesimal("-12d34m56.78s") ≈ -1*π/180.*(12.+34/60.+56.78/3600)
    @test sexagesimal("-12d34m56s")    ≈ -1*π/180.*(12.+34/60.+56./3600)
    @test sexagesimal("-12d34.56m")    ≈ -1*π/180.*(12.+34.56/60.)
    @test sexagesimal("-12d34m")       ≈ -1*π/180.*(12.+34./60.)
    @test sexagesimal("-12.34d")       ≈ -1*π/180.*(12.34)
    @test sexagesimal("-12d")          ≈ -1*π/180.*(12.)

    @test epoch"UTC"  === Measures.Epochs.UTC
    @test epoch"LAST" === Measures.Epochs.LAST

    @test dir"J2000" === Measures.Directions.J2000
    @test dir"AZEL"  === Measures.Directions.AZEL

    @test pos"WGS84" === Measures.Positions.WGS84
    @test pos"ITRF"  === Measures.Positions.ITRF

    @test baseline"ITRF"  === Measures.Baselines.ITRF
    @test baseline"J2000" === Measures.Baselines.J2000

    date = 0.0
    time = Epoch(epoch"UTC",date,"d")
    @test time == Epoch(epoch"UTC",0.0)
    @test repr(time) == "1858-11-17T00:00:00"

    date = 57365.5
    time = Epoch(epoch"UTC",date,"d")
    @test time == Epoch(epoch"UTC",date*24*60*60)
    @test repr(time) == "2015-12-09T12:00:00"

    # atomic time is 36 seconds ahead of UTC time (due to leap seconds)
    frame = ReferenceFrame()
    date = 57365.5
    utc  = Epoch(epoch"UTC",date,"d")
    tai  = measure(frame,utc,epoch"TAI")
    utc′ = measure(frame,tai,epoch"UTC")
    @test utc.sys === utc′.sys === epoch"UTC"
    @test tai.sys === epoch"TAI"
    @test tai.time - utc.time == 36
    @test utc ≈ utc′

    dir = Direction(dir"J2000", "12h00m", "43d21m")
    @test dir.x^2 + dir.y^2 + dir.z^2 ≈ 1
    @test repr(dir) == "180.00000°, 43.35000°"

    dir1 = Direction(dir"J2000", "12h00m", "45d00m")
    dir2 = Direction(dir"J2000", -1/sqrt(2), 0.0, 1/sqrt(2))
    @test dir1 ≈ dir2

    dir = Direction(dir"SUN")
    @test dir == Direction(dir"SUN", 1.0, 0.0, 0.0)
    @test Measures.longitude(dir) == 0
    @test Measures.latitude(dir)  == 0

    frame = ReferenceFrame()
    set!(frame, observatory("OVRO_MMA"))
    set!(frame, Epoch(epoch"UTC", 50237.29, "d"))
    dir1  = Direction(dir"AZEL", "40.0d", "50.0d")
    j2000 = measure(frame,dir1,dir"J2000")
    dir2  = measure(frame,j2000,dir"AZEL")
    @test dir1.sys === dir2.sys === dir"AZEL"
    @test j2000.sys === dir"J2000"
    @test dir1 ≈ dir2
    dir1 = Direction(dir"J2000", "19h59m28.35663s", "+40d44m02.0970s")
    azel = measure(frame,dir1,dir"AZEL")
    dir2 = measure(frame,azel,dir"J2000")
    @test dir1.sys === dir2.sys === dir"J2000"
    @test azel.sys === dir"AZEL"
    @test dir1 ≈ dir2

    frame = ReferenceFrame()
    pos1 = Position(pos"WGS84", 1.0, "20d30m00s", "-80d")
    pos2 = measure(frame,pos1,pos"ITRF")
    pos3 = measure(frame,pos2,pos"WGS84")
    @test pos1.sys === pos3.sys === pos"WGS84"
    @test pos2.sys === pos"ITRF"
    @test pos1 ≈ pos3
    @test repr(pos1) == "1.000 meters, 20.50000°, -80.00000°"

    alma = observatory("ALMA")
    vla  = observatory("VLA")
    @test alma ≈ Position(pos"WGS84", 1.761867423e3, -4.307634996e3, -1.97770831e3)
    @test vla  ≈ Position(pos"ITRF", -1.601185365e6, -5.041977547e6,  3.55487587e6)

    frame = ReferenceFrame()
    set!(frame, observatory("OVRO_MMA"))
    set!(frame, Epoch(epoch"UTC", 50237.29, "d"))
    set!(frame, Direction(dir"AZEL", "0.0d", "90.0d"))
    u, v, w = 1.234, 5.678, 0.100
    baseline1 = Baseline(baseline"ITRF", u, v, w)
    baseline2 = measure(frame,baseline1,baseline"J2000")
    baseline3 = measure(frame,baseline2,baseline"ITRF")
    @test baseline1.sys === baseline3.sys === baseline"ITRF"
    @test baseline2.sys === baseline"J2000"
    @test baseline1 ≈ baseline3
    @test repr(baseline1) == "1.234 meters, 5.678 meters, 0.100 meters"
end

