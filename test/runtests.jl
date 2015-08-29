using CasaCore.Tables
using CasaCore.Quanta
using CasaCore.Measures
using Base.Test

let
    @test get(ra"12h34m56.78s",Radian) ≈ π/12.*(12.+34/60.+56.78/3600)
    @test get(ra"12h34m56s",Radian)    ≈ π/12.*(12.+34/60.+56./3600)
    @test get(ra"12h34.56m",Radian)    ≈ π/12.*(12.+34.56/60.)
    @test get(ra"12h34m",Radian)       ≈ π/12.*(12.+34./60.)
    @test get(ra"12.34h",Radian)       ≈ π/12.*(12.34)
    @test get(ra"12h",Radian)          ≈ π/12.*(12.)

    @test get(dec"12d34m56.78s",Radian)   ≈ π/180.*(12.+34/60.+56.78/3600)
    @test get(dec"12d34m56s",Radian)      ≈ π/180.*(12.+34/60.+56./3600)
    @test get(dec"12d34.56m",Radian)      ≈ π/180.*(12.+34.56/60.)
    @test get(dec"12d34m",Radian)         ≈ π/180.*(12.+34./60.)
    @test get(dec"12.34d",Radian)         ≈ π/180.*(12.34)
    @test get(dec"12d",Radian)            ≈ π/180.*(12.)
    @test get(dec"+12d34m56.78s",Radian)  ≈ π/180.*(12.+34/60.+56.78/3600)
    @test get(dec"+12d34m56s",Radian)     ≈ π/180.*(12.+34/60.+56./3600)
    @test get(dec"+12d34.56m",Radian)     ≈ π/180.*(12.+34.56/60.)
    @test get(dec"+12d34m",Radian)        ≈ π/180.*(12.+34./60.)
    @test get(dec"+12.34d",Radian)        ≈ π/180.*(12.34)
    @test get(dec"+12d",Radian)           ≈ π/180.*(12.)
    @test get(dec"-12d34m56.78s",Radian)  ≈ -1*π/180.*(12.+34/60.+56.78/3600)
    @test get(dec"-12d34m56s",Radian)     ≈ -1*π/180.*(12.+34/60.+56./3600)
    @test get(dec"-12d34.56m",Radian)     ≈ -1*π/180.*(12.+34.56/60.)
    @test get(dec"-12d34m",Radian)        ≈ -1*π/180.*(12.+34./60.)
    @test get(dec"-12.34d",Radian)        ≈ -1*π/180.*(12.34)
    @test get(dec"-12d",Radian)           ≈ -1*π/180.*(12.)

    str = "12h34m56.7890s"
    val = Quanta.get(Quanta.parse_ra(str),Quanta.Degree)
    @test Quanta.format_ra(val) == str
    str = "+12d34m56.7890s"
    val = Quanta.get(Quanta.parse_dec(str),Quanta.Degree)
    @test Quanta.format_dec(val) == str
end

let
    # position of an OVRO LWA antenna
    x = -2.4091659216088112e6
    y = -4.477883063543822e6
    z = 3.8393872424225896e6
    pos = Measures.from_xyz_in_meters(Measures.ITRF,x,y,z)
    ξ,η,ζ = Measures.xyz_in_meters(pos)
    @test Measures.reference(pos) === Measures.ITRF
    @test x == ξ
    @test y == η
    @test z == ζ
    @test length(pos) ≈ sqrt(x^2+y^2+z^2)
end

let
    frame = ReferenceFrame()
    position = observatory("OVRO_MMA")
    time = Epoch(Measures.UTC,Quantity(50237.29,Day))
    set!(frame,position)
    set!(frame,time)

    dir1  = Direction(Measures.AZEL,Quantity(1.0,Radian),Quantity(1.0,Radian))
    j2000 = measure(frame,dir1,Measures.J2000)
    dir2  = measure(frame,j2000,Measures.AZEL)

    @test Measures.reference(dir1)  === Measures.AZEL
    @test Measures.reference(j2000) === Measures.J2000
    @test Measures.reference(dir2)  === Measures.AZEL
    @test  latitude(dir1) ≈  latitude(dir2)
    @test longitude(dir1) ≈ longitude(dir2)

    dir1 = Direction(Measures.J2000,ra"19h59m28.35663s",dec"+40d44m02.0970s")
    azel = measure(frame,dir1,Measures.AZEL)
    dir2 = measure(frame,azel,Measures.J2000)

    @test Measures.reference(dir1) === Measures.J2000
    @test Measures.reference(azel) === Measures.AZEL
    @test Measures.reference(dir2) === Measures.J2000
    @test  latitude(dir1) ≈  latitude(dir2)
    @test longitude(dir1) ≈ longitude(dir2)

    inradians = longitude(dir1,Radian)
    indegrees = longitude(dir1,Degree)
    @test rad2deg(inradians) ≈ indegrees
    inradians = latitude(dir1,Radian)
    indegrees = latitude(dir1,Degree)
    @test rad2deg(inradians) ≈ indegrees
end

let
    srand(123)

    name  = tempname()*".ms"
    table = Table(name)

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

