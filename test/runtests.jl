using CasaCore.Tables
using CasaCore.Measures
using Base.Test

srand(123)

include("tables.jl")

let
    @test get(q"12h34m56.78s","rad") ≈ π/12.*(12.+34/60.+56.78/3600)
    @test get(q"12h34m56s","rad")    ≈ π/12.*(12.+34/60.+56./3600)
    @test get(q"12h34.56m","rad")    ≈ π/12.*(12.+34.56/60.)
    @test get(q"12h34m","rad")       ≈ π/12.*(12.+34./60.)
    @test get(q"12.34h","rad")       ≈ π/12.*(12.34)
    @test get(q"12h","rad")          ≈ π/12.*(12.)

    @test get(q"12d34m56.78s","rad")   ≈ π/180.*(12.+34/60.+56.78/3600)
    @test get(q"12d34m56s","rad")      ≈ π/180.*(12.+34/60.+56./3600)
    @test get(q"12d34.56m","rad")      ≈ π/180.*(12.+34.56/60.)
    @test get(q"12d34m","rad")         ≈ π/180.*(12.+34./60.)
    @test get(q"12.34d","rad")         ≈ π/180.*(12.34)
    @test get(q"12d","rad")            ≈ π/180.*(12.)
    @test get(q"+12d34m56.78s","rad")  ≈ π/180.*(12.+34/60.+56.78/3600)
    @test get(q"+12d34m56s","rad")     ≈ π/180.*(12.+34/60.+56./3600)
    @test get(q"+12d34.56m","rad")     ≈ π/180.*(12.+34.56/60.)
    @test get(q"+12d34m","rad")        ≈ π/180.*(12.+34./60.)
    @test get(q"+12.34d","rad")        ≈ π/180.*(12.34)
    @test get(q"+12d","rad")           ≈ π/180.*(12.)
    @test get(q"-12d34m56.78s","rad")  ≈ -1*π/180.*(12.+34/60.+56.78/3600)
    @test get(q"-12d34m56s","rad")     ≈ -1*π/180.*(12.+34/60.+56./3600)
    @test get(q"-12d34.56m","rad")     ≈ -1*π/180.*(12.+34.56/60.)
    @test get(q"-12d34m","rad")        ≈ -1*π/180.*(12.+34./60.)
    @test get(q"-12.34d","rad")        ≈ -1*π/180.*(12.34)
    @test get(q"-12d","rad")           ≈ -1*π/180.*(12.)
end

let
    frame = ReferenceFrame()

    # position of an OVRO LWA antenna
    x = -2.4091659216088112e6
    y = -4.477883063543822e6
    z = 3.8393872424225896e6
    pos = Measures.from_xyz_in_meters(pos"ITRF",x,y,z)
    ξ,η,ζ = Measures.xyz_in_meters(pos)
    @test coordinate_system(pos) === pos"ITRF"
    @test x == ξ
    @test y == η
    @test z == ζ
    @test length(pos) ≈ sqrt(x^2+y^2+z^2)

    pos1 = Position(pos"WGS84",q"1.0m",q"0.5rad",q"0.1rad")
    pos2 = measure(frame,pos1,pos"ITRF")
    pos3 = measure(frame,pos2,pos"WGS84")
    @test coordinate_system(pos3) === coordinate_system(pos1)
    @test    length(pos3) ≈    length(pos1)
    @test longitude(pos3) ≈ longitude(pos1)
    @test  latitude(pos3) ≈  latitude(pos1)
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
    x,y,z = Measures.xyz_in_meters(dir1)
    dir2 = Measures.from_xyz_in_meters(dir"J2000",x,y,z)
    @test coordinate_system(dir1) === coordinate_system(dir2)
    @test longitude(dir1) ≈ longitude(dir2)
    @test  latitude(dir1) ≈  latitude(dir2)

    dir = Direction(dir"SUN")
    @test coordinate_system(dir) === dir"SUN"
    @test longitude(dir,"rad") ≈ 0.0
    @test  latitude(dir,"rad") ≈ 0.0
end

let
    frame = ReferenceFrame()

    date = 50237.29
    time = Epoch(epoch"UTC",Quantity(date,"d"))
    @test coordinate_system(time) === epoch"UTC"
    @test days(time) == date
    @test seconds(time) == date*24*60*60

    tai = Epoch(epoch"TAI",Quantity(date,"d"))
    @test coordinate_system(tai) === epoch"TAI"
    @test days(time) == date
    @test seconds(time) == date*24*60*60

    utc = measure(frame,tai,epoch"UTC")
    @test coordinate_system(utc) === epoch"UTC"
    tai_again = measure(frame,utc,epoch"TAI")
    @test coordinate_system(tai_again) === epoch"TAI"
    @test days(tai_again) == date
end

