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
    srand(123)

    name  = tempname()*".ms"
    @show name
    table = Table(name)
    addScalarColumn!(table,"ANTENNA1","int")
    addScalarColumn!(table,"ANTENNA2","int")
    addArrayColumn!(table,"UVW","double",[3])
    addArrayColumn!(table,"DATA","complex",[4,109])
    addArrayColumn!(table,"MODEL_DATA","complex",[4,109])
    addArrayColumn!(table,"CORRECTED_DATA","complex",[4,109])
    addRows!(table,10)

    @test    nrows(table) == 10
    @test ncolumns(table) ==  6
    removeRows!(table,[6:10])
    @test    nrows(table) ==  5
    @test ncolumns(table) ==  6

    ant1 = Array(Cint,5)
    ant2 = Array(Cint,5)
    rand!(ant1); rand!(ant2)
    putColumn!(table,"ANTENNA1",ant1)
    putColumn!(table,"ANTENNA2",ant2)
    @test getColumn(table,"ANTENNA1") == ant1
    @test getColumn(table,"ANTENNA2") == ant2

    uvw = Array(Cdouble,3,5)
    rand!(uvw)
    putColumn!(table,"UVW",uvw)
    @test getColumn(table,"UVW") == uvw

    data      = Array(Complex{Cfloat},4,109,5)
    model     = Array(Complex{Cfloat},4,109,5)
    corrected = Array(Complex{Cfloat},4,109,5)
    rand!(data); rand!(model); rand!(corrected)
    putColumn!(table,"DATA",data)
    putColumn!(table,"MODEL_DATA",model)
    putColumn!(table,"CORRECTED_DATA",corrected)
    @test getColumn(table,"DATA") == data
    @test getColumn(table,"MODEL_DATA") == model
    @test getColumn(table,"CORRECTED_DATA") == corrected

    # Close the table and open it as a MeasurementSet
    finalize(table)
    ms = MeasurementSet(name)

    @test getAntenna1(ms) == ant1+1
    @test getAntenna2(ms) == ant2+1

    u,v,w = getUVW(ms)
    @test u == uvw[1,:]
    @test v == uvw[2,:]
    @test w == uvw[3,:]

    # Test getData/getModelData/getCorrectedData twice
    # to make sure the cache is being used properly.
    @test getData(ms) == data
    @test getData(ms) == data
    @test getModelData(ms) == model
    @test getModelData(ms) == model
    @test getCorrectedData(ms) == corrected
    @test getCorrectedData(ms) == corrected
    rand!(data); rand!(model); rand!(corrected)
    putData!(ms,data)
    putModelData!(ms,model)
    putCorrectedData!(ms,corrected)
    @test getData(ms) == data
    @test getData(ms) == data
    @test getModelData(ms) == model
    @test getModelData(ms) == model
    @test getCorrectedData(ms) == corrected
    @test getCorrectedData(ms) == corrected
end

