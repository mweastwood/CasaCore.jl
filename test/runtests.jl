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

function test_epoch()
    frame = ReferenceFrame()
    position = observatory(frame,"OVRO_MMA")
    time = Measure("epoch","UTC",Quantity(4.905577293531662e9,"s"))
    set!(frame,position)
    set!(frame,time)

    dir1  = Measure("direction","AZEL",Quantity(0.,"rad"),Quantity(π/2-1,"rad"))
    j2000 = measure(frame,dir1,"J2000")
    dir2  = measure(frame,j2000,"AZEL")

    test_approx_eq(dir1,dir2)
end
test_epoch()

