using CasaCore
using Base.Test

tol = 10eps(Float64)

function test_approx_eq(m1::Measure,m2::Measure)
    @test m1.measuretype == m2.measuretype
    @test m1.system == m2.system
    for (q1,q2) in zip(m1.m,m2.m)
        @test_approx_eq_eps q1.value q2.value tol
        @test q1.unit == q2.unit
    end
end

let
    @test q"1234.5s" == Quantity(1234.5,"s")
    @test q"1.23e4s" == Quantity(1.23e4,"s")
    @test q"1.23rad" == Quantity(1.23,"rad")
    @test q"12h00m00.00s" == Quantity(float(π),"rad")
    @test q"12h00m00s"    == Quantity(float(π),"rad")
    @test q"12h00.00m"    == Quantity(float(π),"rad")
    @test q"12h00m"       == Quantity(float(π),"rad")
    @test q"12.00h"       == Quantity(float(π),"rad")
    @test q"12h"          == Quantity(float(π),"rad")
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
    table = Table(name)
    addScalarColumn!(table,"ANTENNA1","int")
    addScalarColumn!(table,"ANTENNA2","int")
    addRows!(table,10)

    @test    nrows(table) == 10
    @test ncolumns(table) == 2
    removeRows!(table,[6:10])
    @test    nrows(table) == 5
    @test ncolumns(table) == 2
end

