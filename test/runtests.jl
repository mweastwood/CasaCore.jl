using CasaCore
using Base.Test

function test_approx_eq(q1::Quantity,q2::Quantity,tol = 5eps(Float64))
    @test_approx_eq_eps q1.value q2.value tol
    @test q1.unit == q2.unit
end

function test_approx_eq(m1::Measure,m2::Measure)
    @test m1.measuretype == m2.measuretype
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
    position = observatory(frame,"OVRO_MMA")
    time = Epoch("UTC",q"4.905577293531662e9s")
    set!(frame,position)
    set!(frame,time)

    dir1  = Direction("AZEL",q"0.0rad",q"1.0rad")
    j2000 = measure(frame,"J2000",dir1)
    dir2  = measure(frame,"AZEL",j2000)

    test_approx_eq(dir1,dir2)
end

let
    name  = tempname()*".ms"
    println(name)
    table = Table(name)
    addScalarColumn!(table,"ANTENNA1","int")
    addScalarColumn!(table,"ANTENNA2","int")
    addArrayColumn!(table,"UVW","double",[3])
    addArrayColumn!(table,"DATA","complex",[4,109])
    addRows!(table,10)

    @test    nrows(table) == 10
    @test ncolumns(table) == 4

    removeRows!(table,[6:10])

    @test    nrows(table) == 5
    @test ncolumns(table) == 4

    ant1 = Int32[1:5]
    ant2 = Int32[6:10]
    uvw  = ones(Float64,3,5)
    data = ones(Complex64,4,109,5)

    putColumn!(table,"ANTENNA1",ant1)
    putColumn!(table,"ANTENNA2",ant2)
    putColumn!(table,"UVW",uvw)
    putColumn!(table,"DATA",data)

    @test getColumn(table,"ANTENNA1") == ant1
    @test getColumn(table,"ANTENNA2") == ant2
    @test getColumn(table,"UVW") == uvw
    @test getColumn(table,"DATA") == data
end

