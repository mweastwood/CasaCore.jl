using CasaCore.Tables
using CasaCore.Measures
using Base.Test
using SIUnits

function test_approx_eq(q1::SIUnits.SIQuantity,q2::SIUnits.SIQuantity,tol = 3eps(Float64))
    # This function is necesary because SIUnits does not (yet) support @test_approx_eq.
    # Note that this function does not test for the equality of the units.
    @test_approx_eq_eps q1.val q2.val tol
end

function test_approx_eq{T<:Measure}(m1::T,m2::T)
    @test m1.system == m2.system
    for (q1,q2) in zip(m1.m,m2.m)
        test_approx_eq(q1,q2)
    end
end

let
    test_approx_eq(ra"12h34m56.78s",π/12.*(12.+34/60.+56.78/3600)*Radian)
    test_approx_eq(ra"12h34m56s",   π/12.*(12.+34/60.+56./3600)*Radian)
    test_approx_eq(ra"12h34.56m",   π/12.*(12.+34.56/60.)*Radian)
    test_approx_eq(ra"12h34m",      π/12.*(12.+34./60.)*Radian)
    test_approx_eq(ra"12.34h",      π/12.*(12.34)*Radian)
    test_approx_eq(ra"12h",         π/12.*(12.)*Radian)

    test_approx_eq(dec"12d34m56.78s",  π/180.*(12.+34/60.+56.78/3600)*Radian)
    test_approx_eq(dec"12d34m56s",     π/180.*(12.+34/60.+56./3600)*Radian)
    test_approx_eq(dec"12d34.56m",     π/180.*(12.+34.56/60.)*Radian)
    test_approx_eq(dec"12d34m",        π/180.*(12.+34./60.)*Radian)
    test_approx_eq(dec"12.34d",        π/180.*(12.34)*Radian)
    test_approx_eq(dec"12d",           π/180.*(12.)*Radian)
    test_approx_eq(dec"+12d34m56.78s", π/180.*(12.+34/60.+56.78/3600)*Radian)
    test_approx_eq(dec"+12d34m56s",    π/180.*(12.+34/60.+56./3600)*Radian)
    test_approx_eq(dec"+12d34.56m",    π/180.*(12.+34.56/60.)*Radian)
    test_approx_eq(dec"+12d34m",       π/180.*(12.+34./60.)*Radian)
    test_approx_eq(dec"+12.34d",       π/180.*(12.34)*Radian)
    test_approx_eq(dec"+12d",          π/180.*(12.)*Radian)
    test_approx_eq(dec"-12d34m56.78s", -1*π/180.*(12.+34/60.+56.78/3600)*Radian)
    test_approx_eq(dec"-12d34m56s",    -1*π/180.*(12.+34/60.+56./3600)*Radian)
    test_approx_eq(dec"-12d34.56m",    -1*π/180.*(12.+34.56/60.)*Radian)
    test_approx_eq(dec"-12d34m",       -1*π/180.*(12.+34./60.)*Radian)
    test_approx_eq(dec"-12.34d",       -1*π/180.*(12.34)*Radian)
    test_approx_eq(dec"-12d",          -1*π/180.*(12.)*Radian)
end

let
    frame = ReferenceFrame()
    position = Measures.observatory(frame,"OVRO_MMA")
    time = Epoch("UTC",4.905577293531662e9Second)
    set!(frame,position)
    set!(frame,time)

    dir1  = Direction("AZEL",0.0Radian,1.0Radian)
    j2000 = measure(frame,dir1,"J2000")
    dir2  = measure(frame,j2000,"AZEL")

    test_approx_eq(dir1,dir2)
end

let
    srand(123)

    name  = tempname()*".ms"
    @show name
    table = Table(name)

    Tables.addRows!(table,10)
    @test numrows(table) == 10
    Tables.removeRows!(table,[6:10])
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

