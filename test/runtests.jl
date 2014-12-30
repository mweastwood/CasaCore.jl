using CasaCore.Tables
using CasaCore.Measures
using Base.Test

function test_approx_eq(q1::Quantity,q2::Quantity,tol = 5eps(Float64))
    @test_approx_eq_eps q1.value q2.value tol
    @test q1.unit == q2.unit
end

function test_approx_eq{T<:Measure}(m1::T,m2::T)
    @test m1.system == m2.system
    for (q1,q2) in zip(m1.m,m2.m)
        test_approx_eq(q1,q2)
    end
end

let
    @test q"1234.5s"  == Quantity(1234.5,"s")
    @test q"1.23e4s"  == Quantity(1.23e4,"s")
    @test q"1.23rad"  == Quantity(1.23,"rad")
    @test q"+1234.5s" == Quantity(1234.5,"s")
    @test q"+1.23e4s" == Quantity(1.23e4,"s")
    @test q"+1.23rad" == Quantity(1.23,"rad")
    @test q"-1234.5s" == Quantity(-1234.5,"s")
    @test q"-1.23e4s" == Quantity(-1.23e4,"s")
    @test q"-1.23rad" == Quantity(-1.23,"rad")

    test_approx_eq(q"12h34m56.78s",Quantity(π/12.*(12.+34/60.+56.78/3600),"rad"))
    test_approx_eq(q"12h34m56s",   Quantity(π/12.*(12.+34/60.+56./3600),"rad"))
    test_approx_eq(q"12h34.56m",   Quantity(π/12.*(12.+34.56/60.),"rad"))
    test_approx_eq(q"12h34m",      Quantity(π/12.*(12.+34./60.),"rad"))
    test_approx_eq(q"12.34h",      Quantity(π/12.*(12.34),"rad"))
    test_approx_eq(q"12h",         Quantity(π/12.*(12.),"rad"))

    test_approx_eq(q"12d34m56.78s", Quantity(π/180.*(12.+34/60.+56.78/3600),"rad"))
    test_approx_eq(q"12d34m56s",    Quantity(π/180.*(12.+34/60.+56./3600),"rad"))
    test_approx_eq(q"12d34.56m",    Quantity(π/180.*(12.+34.56/60.),"rad"))
    test_approx_eq(q"12d34m",       Quantity(π/180.*(12.+34./60.),"rad"))
    test_approx_eq(q"12.34d",       Quantity(π/180.*(12.34),"rad"))
    test_approx_eq(q"12d",          Quantity(π/180.*(12.),"rad"))
    test_approx_eq(q"+12d34m56.78s",Quantity(π/180.*(12.+34/60.+56.78/3600),"rad"))
    test_approx_eq(q"+12d34m56s",   Quantity(π/180.*(12.+34/60.+56./3600),"rad"))
    test_approx_eq(q"+12d34.56m",   Quantity(π/180.*(12.+34.56/60.),"rad"))
    test_approx_eq(q"+12d34m",      Quantity(π/180.*(12.+34./60.),"rad"))
    test_approx_eq(q"+12.34d",      Quantity(π/180.*(12.34),"rad"))
    test_approx_eq(q"+12d",         Quantity(π/180.*(12.),"rad"))
    test_approx_eq(q"-12d34m56.78s",Quantity(-π/180.*(12.+34/60.+56.78/3600),"rad"))
    test_approx_eq(q"-12d34m56s",   Quantity(-π/180.*(12.+34/60.+56./3600),"rad"))
    test_approx_eq(q"-12d34.56m",   Quantity(-π/180.*(12.+34.56/60.),"rad"))
    test_approx_eq(q"-12d34m",      Quantity(-π/180.*(12.+34./60.),"rad"))
    test_approx_eq(q"-12.34d",      Quantity(-π/180.*(12.34),"rad"))
    test_approx_eq(q"-12d",         Quantity(-π/180.*(12.),"rad"))
end

let
    frame = ReferenceFrame()
    position = Measures.observatory(frame,"OVRO_MMA")
    time = Epoch("UTC",q"4.905577293531662e9s")
    set!(frame,position)
    set!(frame,time)

    dir1  = Direction("AZEL",q"0.0rad",q"1.0rad")
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

    subtable = Table("$name/SPECTRAL_WINDOW")
    Tables.addRows!(subtable,1)
    subtable["CHAN_FREQ"] = freq
    @test subtable["CHAN_FREQ"] == freq
    finalize(subtable)

    @test numkeywords(table) == 0
    table[kw"SPECTRAL_WINDOW"] = "Table: $name/SPECTRAL_WINDOW"
    @test numkeywords(table) == 1
    @test table[kw"SPECTRAL_WINDOW"] == "Table: $name/SPECTRAL_WINDOW"
end

