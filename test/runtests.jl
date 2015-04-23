using CasaCore.Tables
using CasaCore.Quanta
using CasaCore.Measures
using Base.Test

let
    @test_approx_eq get(ra"12h34m56.78s",Radian) π/12.*(12.+34/60.+56.78/3600)
    @test_approx_eq get(ra"12h34m56s",Radian)    π/12.*(12.+34/60.+56./3600)
    @test_approx_eq get(ra"12h34.56m",Radian)    π/12.*(12.+34.56/60.)
    @test_approx_eq get(ra"12h34m",Radian)       π/12.*(12.+34./60.)
    @test_approx_eq get(ra"12.34h",Radian)       π/12.*(12.34)
    @test_approx_eq get(ra"12h",Radian)          π/12.*(12.)

    @test_approx_eq get(dec"12d34m56.78s",Radian)   π/180.*(12.+34/60.+56.78/3600)
    @test_approx_eq get(dec"12d34m56s",Radian)      π/180.*(12.+34/60.+56./3600)
    @test_approx_eq get(dec"12d34.56m",Radian)      π/180.*(12.+34.56/60.)
    @test_approx_eq get(dec"12d34m",Radian)         π/180.*(12.+34./60.)
    @test_approx_eq get(dec"12.34d",Radian)         π/180.*(12.34)
    @test_approx_eq get(dec"12d",Radian)            π/180.*(12.)
    @test_approx_eq get(dec"+12d34m56.78s",Radian)  π/180.*(12.+34/60.+56.78/3600)
    @test_approx_eq get(dec"+12d34m56s",Radian)     π/180.*(12.+34/60.+56./3600)
    @test_approx_eq get(dec"+12d34.56m",Radian)     π/180.*(12.+34.56/60.)
    @test_approx_eq get(dec"+12d34m",Radian)        π/180.*(12.+34./60.)
    @test_approx_eq get(dec"+12.34d",Radian)        π/180.*(12.34)
    @test_approx_eq get(dec"+12d",Radian)           π/180.*(12.)
    @test_approx_eq get(dec"-12d34m56.78s",Radian)  -1*π/180.*(12.+34/60.+56.78/3600)
    @test_approx_eq get(dec"-12d34m56s",Radian)     -1*π/180.*(12.+34/60.+56./3600)
    @test_approx_eq get(dec"-12d34.56m",Radian)     -1*π/180.*(12.+34.56/60.)
    @test_approx_eq get(dec"-12d34m",Radian)        -1*π/180.*(12.+34./60.)
    @test_approx_eq get(dec"-12.34d",Radian)        -1*π/180.*(12.34)
    @test_approx_eq get(dec"-12d",Radian)           -1*π/180.*(12.)
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

    @test_approx_eq  latitude(dir1)  latitude(dir2)
    @test_approx_eq longitude(dir1) longitude(dir2)
end

let
    srand(123)

    name  = tempname()*".ms"
    @show name
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
end

