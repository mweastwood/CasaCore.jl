using CasaCore.Tables
using CasaCore.Measures
using Base.Test

let
    @test get(q"12h34m56.78s",Unit("rad")) ≈ π/12.*(12.+34/60.+56.78/3600)
    @test get(q"12h34m56s",Unit("rad"))    ≈ π/12.*(12.+34/60.+56./3600)
    @test get(q"12h34.56m",Unit("rad"))    ≈ π/12.*(12.+34.56/60.)
    @test get(q"12h34m",Unit("rad"))       ≈ π/12.*(12.+34./60.)
    @test get(q"12.34h",Unit("rad"))       ≈ π/12.*(12.34)
    @test get(q"12h",Unit("rad"))          ≈ π/12.*(12.)

    @test get(q"12d34m56.78s",Unit("rad"))   ≈ π/180.*(12.+34/60.+56.78/3600)
    @test get(q"12d34m56s",Unit("rad"))      ≈ π/180.*(12.+34/60.+56./3600)
    @test get(q"12d34.56m",Unit("rad"))      ≈ π/180.*(12.+34.56/60.)
    @test get(q"12d34m",Unit("rad"))         ≈ π/180.*(12.+34./60.)
    @test get(q"12.34d",Unit("rad"))         ≈ π/180.*(12.34)
    @test get(q"12d",Unit("rad"))            ≈ π/180.*(12.)
    @test get(q"+12d34m56.78s",Unit("rad"))  ≈ π/180.*(12.+34/60.+56.78/3600)
    @test get(q"+12d34m56s",Unit("rad"))     ≈ π/180.*(12.+34/60.+56./3600)
    @test get(q"+12d34.56m",Unit("rad"))     ≈ π/180.*(12.+34.56/60.)
    @test get(q"+12d34m",Unit("rad"))        ≈ π/180.*(12.+34./60.)
    @test get(q"+12.34d",Unit("rad"))        ≈ π/180.*(12.34)
    @test get(q"+12d",Unit("rad"))           ≈ π/180.*(12.)
    @test get(q"-12d34m56.78s",Unit("rad"))  ≈ -1*π/180.*(12.+34/60.+56.78/3600)
    @test get(q"-12d34m56s",Unit("rad"))     ≈ -1*π/180.*(12.+34/60.+56./3600)
    @test get(q"-12d34.56m",Unit("rad"))     ≈ -1*π/180.*(12.+34.56/60.)
    @test get(q"-12d34m",Unit("rad"))        ≈ -1*π/180.*(12.+34./60.)
    @test get(q"-12.34d",Unit("rad"))        ≈ -1*π/180.*(12.34)
    @test get(q"-12d",Unit("rad"))           ≈ -1*π/180.*(12.)
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

    pos1 = Position(pos"WGS84",
                    Quantity(1.0,Unit("m")),
                    Quantity(0.5,Unit("rad")),
                    Quantity(0.1,Unit("rad")))
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
    time = Epoch(epoch"UTC",Quantity(50237.29,Unit("d")))
    set!(frame,position)
    set!(frame,time)

    dir1  = Direction(dir"AZEL",Quantity(1.0,Unit("rad")),Quantity(1.0,Unit("rad")))
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

    inradians = longitude(dir1,Unit("rad"))
    indegrees = longitude(dir1,Unit("deg"))
    @test rad2deg(inradians) ≈ indegrees
    inradians = latitude(dir1,Unit("rad"))
    indegrees = latitude(dir1,Unit("deg"))
    @test rad2deg(inradians) ≈ indegrees

    dir1 = Direction(dir"J2000",q"19h59m28.35663s",q"+40d44m02.0970s")
    x,y,z = Measures.xyz_in_meters(dir1)
    dir2 = Measures.from_xyz_in_meters(dir"J2000",x,y,z)
    @test coordinate_system(dir1) === coordinate_system(dir2)
    @test longitude(dir1) ≈ longitude(dir2)
    @test  latitude(dir1) ≈  latitude(dir2)

    dir = Direction(dir"SUN")
    @test coordinate_system(dir) === dir"SUN"
    @test longitude(dir,Unit("rad")) ≈ 0.0
    @test  latitude(dir,Unit("rad")) ≈ 0.0
end

let
    frame = ReferenceFrame()

    date = 50237.29
    time = Epoch(epoch"UTC",Quantity(date,Unit("d")))
    @test coordinate_system(time) === epoch"UTC"
    @test days(time) == date
    @test seconds(time) == date*24*60*60

    tai = Epoch(epoch"TAI",Quantity(date,Unit("d")))
    @test coordinate_system(tai) === epoch"TAI"
    @test days(time) == date
    @test seconds(time) == date*24*60*60

    utc = measure(frame,tai,epoch"UTC")
    @test coordinate_system(utc) === epoch"UTC"
    tai_again = measure(frame,utc,epoch"TAI")
    @test coordinate_system(tai_again) === epoch"TAI"
    @test days(tai_again) == date
end

let
    srand(123)

    name  = tempname()*".ms"
    table = Table(name)

    @test Tables.iswritable(table) == true
    @test Tables.isreadable(table) == true

    Tables.addRows!(table,10)
    @test numrows(table) == 10
    Tables.removeRows!(table,[6:10;])
    @test numrows(table) ==  5

    ant1 = Array(Int32,5)
    ant2 = Array(Int32,5)
    uvw  = Array(Float64,3,5)
    time = Array(Float64,5)
    data      = Array(Complex64,4,109,5)
    model     = Array(Complex64,4,109,5)
    corrected = Array(Complex64,4,109,5)
    freq = Array(Float64,109,1)

    rand!(ant1)
    rand!(ant2)
    rand!(uvw)
    rand!(time)
    rand!(data)
    rand!(model)
    rand!(corrected)
    rand!(freq)

    table["ANTENNA1"] = ant1
    table["ANTENNA2"] = ant2
    table["UVW"]      = uvw
    table["TIME"]     = time
    table["DATA"]           = data
    table["MODEL_DATA"]     = model
    table["CORRECTED_DATA"] = corrected

    @test numcolumns(table) == 7
    @test Tables.checkColumnExists(table,"ANTENNA1") == true
    @test Tables.checkColumnExists(table,"ANTENNA2") == true
    @test Tables.checkColumnExists(table,"UVW")      == true
    @test Tables.checkColumnExists(table,"TIME")     == true
    @test Tables.checkColumnExists(table,"DATA")            == true
    @test Tables.checkColumnExists(table,"MODEL_DATA")      == true
    @test Tables.checkColumnExists(table,"CORRECTED_DATA")  == true
    @test Tables.checkColumnExists(table,"FABRICATED_DATA") == false

    @test table["ANTENNA1"] == ant1
    @test table["ANTENNA2"] == ant2
    @test table["UVW"]      == uvw
    @test table["TIME"]     == time
    @test table["DATA"]           == data
    @test table["MODEL_DATA"]     == model
    @test table["CORRECTED_DATA"] == corrected
    @test_throws ErrorException table["FABRICATED_DATA"]

    @test table["ANTENNA1",1] == ant1[1]
    @test table["ANTENNA2",1] == ant2[1]
    @test table["UVW",1]      == uvw[:,1]
    @test table["TIME",1]     == time[1]
    @test table["DATA",1]           == data[:,:,1]
    @test table["MODEL_DATA",1]     == model[:,:,1]
    @test table["CORRECTED_DATA",1] == corrected[:,:,1]
    @test_throws ErrorException table["FABRICATED_DATA",1]

    rand!(ant1)
    rand!(ant2)
    rand!(uvw)
    rand!(time)
    rand!(data)
    rand!(model)
    rand!(corrected)
    rand!(freq)

    table["ANTENNA1",1] = ant1[1]
    table["ANTENNA2",1] = ant2[1]
    table["UVW",1]      = uvw[:,1]
    table["TIME",1]     = time[1]
    table["DATA",1]           = data[:,:,1]
    table["MODEL_DATA",1]     = model[:,:,1]
    table["CORRECTED_DATA",1] = corrected[:,:,1]

    @test table["ANTENNA1",1] == ant1[1]
    @test table["ANTENNA2",1] == ant2[1]
    @test table["UVW",1]      == uvw[:,1]
    @test table["TIME",1]     == time[1]
    @test table["DATA",1]           == data[:,:,1]
    @test table["MODEL_DATA",1]     == model[:,:,1]
    @test table["CORRECTED_DATA",1] == corrected[:,:,1]
    @test_throws ErrorException table["FABRICATED_DATA",1]

    subtable = Table("$name/SPECTRAL_WINDOW")
    Tables.addRows!(subtable,1)
    subtable["CHAN_FREQ"] = freq
    @test subtable["CHAN_FREQ"] == freq
    finalize(subtable)

    @test numkeywords(table) == 0
    table[kw"SPECTRAL_WINDOW"] = "Table: $name/SPECTRAL_WINDOW"
    @test numkeywords(table) == 1
    @test table[kw"SPECTRAL_WINDOW"] == "Table: $name/SPECTRAL_WINDOW"

    table["DATA",kw"Hello,"] = "World!"
    @test table["DATA",kw"Hello,"] == "World!"
    table["DATA",kw"Test"] = ["Hello,","World!"]
    @test table["DATA",kw"Test"] == ["Hello,","World!"]

    # Try locking and unlocking the table
    unlock(table)
    lock(table)
    unlock(table)
end

