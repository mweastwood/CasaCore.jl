let
    @test pos"WGS84" === Measures.Types_of_Positions.WGS84
    @test pos"ITRF" === Measures.Types_of_Positions.ITRF
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

    pos = Position(pos"ITRF",q"1.0m",q"0.0deg",q"0.0deg")
    @test repr(pos) == "(1.0 m, 0.0 deg, 0.0 deg)"
end

