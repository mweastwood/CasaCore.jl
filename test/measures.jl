# Copyright (c) 2015-2017 Michael Eastwood
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

@testset "Measures" begin

    @testset "errors" begin
        @test repr(CasaCoreMeasuresError("hello")) == "CasaCoreMeasuresError: hello"
    end

    @testset "sexagesimal" begin
        @test sexagesimal("12h34m56.78s") ≈ π/12.*(12.+34/60.+56.78/3600)
        @test sexagesimal("12h34m56s")    ≈ π/12.*(12.+34/60.+56./3600)
        @test sexagesimal("12h34.56m")    ≈ π/12.*(12.+34.56/60)
        @test sexagesimal("12h34m")       ≈ π/12.*(12.+34./60)
        @test sexagesimal("12.34h")       ≈ π/12.*(12.34)
        @test sexagesimal("12h")          ≈ π/12.*(12)
        @test sexagesimal("-0h34m56.78s") ≈ -π/12.*(34/60.+56.78/3600)
        @test sexagesimal("+0h34m56.78s") ≈ π/12.*(34/60.+56.78/3600)

        @test sexagesimal("12d34m56.78s")  ≈ π/180.*(12.+34/60.+56.78/3600)
        @test sexagesimal("12d34m56s")     ≈ π/180.*(12.+34/60.+56./3600)
        @test sexagesimal("12d34.56m")     ≈ π/180.*(12.+34.56/60)
        @test sexagesimal("12d34m")        ≈ π/180.*(12.+34./60)
        @test sexagesimal("12.34d")        ≈ π/180.*(12.34)
        @test sexagesimal("12d")           ≈ π/180.*(12.)
        @test sexagesimal("+12d34m56.78s") ≈ π/180.*(12.+34/60.+56.78/3600)
        @test sexagesimal("+12d34m56s")    ≈ π/180.*(12.+34/60.+56./3600)
        @test sexagesimal("+12d34.56m")    ≈ π/180.*(12.+34.56/60.)
        @test sexagesimal("+12d34m")       ≈ π/180.*(12.+34./60.)
        @test sexagesimal("+12.34d")       ≈ π/180.*(12.34)
        @test sexagesimal("+12d")          ≈ π/180.*(12.)
        @test sexagesimal("-12d34m56.78s") ≈ -1*π/180.*(12.+34/60.+56.78/3600)
        @test sexagesimal("-12d34m56s")    ≈ -1*π/180.*(12.+34/60.+56./3600)
        @test sexagesimal("-12d34.56m")    ≈ -1*π/180.*(12.+34.56/60)
        @test sexagesimal("-12d34m")       ≈ -1*π/180.*(12.+34./60)
        @test sexagesimal("-12.34d")       ≈ -1*π/180.*(12.34)
        @test sexagesimal("-12d")          ≈ -1*π/180.*(12.)
        @test sexagesimal("-0d34m56.78s")  ≈ -π/180.*(34/60.+56.78/3600)
        @test sexagesimal("+0d34m56.78s")  ≈ π/180.*(34/60.+56.78/3600)

        @test sexagesimal(sexagesimal("5d"))                     == "+5d00m00s"
        @test sexagesimal(sexagesimal("180d"))                   == "+180d00m00s"
        @test sexagesimal(sexagesimal("12d34m56s"))              == "+12d34m56s"
        @test sexagesimal(sexagesimal("12d34m56.78s"))           == "+12d34m57s"
        @test sexagesimal(sexagesimal("12d34m56.78s"),digits=2)  == "+12d34m56.78s"
        @test sexagesimal(sexagesimal("-12d34m56s"))             == "-12d34m56s"
        @test sexagesimal(sexagesimal("-12d34m56.78s"))          == "-12d34m57s"
        @test sexagesimal(sexagesimal("-12d34m56.78s"),digits=2) == "-12d34m56.78s"
        @test sexagesimal(sexagesimal("-0d34m56.78s"),digits=2)  == "-0d34m56.78s"
        @test sexagesimal(sexagesimal("+0d34m56.78s"),digits=2)  == "+0d34m56.78s"
        @test sexagesimal(sexagesimal("5h"),hours=true)                     == "5h00m00s"
        @test sexagesimal(sexagesimal("12h34m56s"),hours=true)              == "12h34m56s"
        @test sexagesimal(sexagesimal("12h34m56.78s"),hours=true)           == "12h34m57s"
        @test sexagesimal(sexagesimal("12h34m56.78s"),hours=true,digits=2)  == "12h34m56.78s"
        @test sexagesimal(sexagesimal("-12h34m56s"),hours=true)             == "11h25m04s"
        @test sexagesimal(sexagesimal("-12h34m56.78s"),hours=true)          == "11h25m03s"
        @test sexagesimal(sexagesimal("-12h34m56.78s"),hours=true,digits=2) == "11h25m03.22s"
        @test sexagesimal(sexagesimal("-0h34m56.78s"),hours=true,digits=2)  == "23h25m03.22s"
        @test sexagesimal(sexagesimal("+0h34m56.78s"),hours=true,digits=2)  == "0h34m56.78s"
        @test sexagesimal(20.5u"°") == "+20d30m00s"
        @test sexagesimal(1.23u"rad") == "+70d28m26s"
    end

    @testset "epochs" begin
        @test epoch"UTC"  === Measures.Epochs.UTC
        @test epoch"LAST" === Measures.Epochs.LAST

        date = 0.0
        time = Epoch(epoch"UTC",date*u"d")
        @test time == Epoch(epoch"UTC",0.0)
        @test repr(time) == "1858-11-17T00:00:00"

        date = 57365.5
        time = Epoch(epoch"UTC",date*u"d")
        @test time == Epoch(epoch"UTC",date*24*60*60)
        @test repr(time) == "2015-12-09T12:00:00"

        # atomic time is 36 seconds ahead of UTC time (due to leap seconds)
        frame = ReferenceFrame()
        date = 57365.5
        utc  = Epoch(epoch"UTC",date*u"d")
        tai  = measure(frame,utc,epoch"TAI")
        utc′ = measure(frame,tai,epoch"UTC")
        @test utc.sys === utc′.sys === epoch"UTC"
        @test tai.sys === epoch"TAI"
        @test tai.time - utc.time == 36
        @test utc ≈ utc′

        @test Measures.units(Epoch) == Measures.units(utc) == u"s"
    end

    @testset "directions" begin
        @test dir"J2000" === Measures.Directions.J2000
        @test dir"AZEL"  === Measures.Directions.AZEL

        dir = Direction(dir"J2000", "12h00m", "43d21m")
        @test norm(dir) ≈ 1
        @test longitude(dir) ≈ π
        @test latitude(dir) ≈ 43.35 * π/180
        @test repr(dir) == "+180d00m00s, +43d21m00s"

        dir1 = Direction(dir"J2000", "12h00m", "45d00m")
        dir2 = Direction(dir"J2000", -1/sqrt(2), 0.0, 1/sqrt(2))
        @test dir1 ≈ dir2

        dir = Direction(dir"SUN")
        @test dir == Direction(dir"SUN", 1.0, 0.0, 0.0)
        @test longitude(dir) == 0
        @test latitude(dir)  == 0

        frame = ReferenceFrame()
        set!(frame, observatory("OVRO_MMA"))
        set!(frame, Epoch(epoch"UTC", 50237.29u"d"))
        dir1  = Direction(dir"AZEL", "40.0d", "50.0d")
        j2000 = measure(frame,dir1,dir"J2000")
        dir2  = measure(frame,j2000,dir"AZEL")
        @test dir1.sys === dir2.sys === dir"AZEL"
        @test j2000.sys === dir"J2000"
        @test dir1 ≈ dir2
        dir1 = Direction(dir"J2000", "19h59m28.35663s", "+40d44m02.0970s")
        azel = measure(frame,dir1,dir"AZEL")
        dir2 = measure(frame,azel,dir"J2000")
        @test dir1.sys === dir2.sys === dir"J2000"
        @test azel.sys === dir"AZEL"
        @test dir1 ≈ dir2

        @test Measures.units(Direction) == Measures.units(dir1) == 1
    end

    @testset "positions" begin
        @test pos"WGS84" === Measures.Positions.WGS84
        @test pos"ITRF"  === Measures.Positions.ITRF

        frame = ReferenceFrame()
        pos1 = Position(pos"WGS84", 5_000u"m", "20d30m00s", "-80d")
        pos2 = measure(frame,pos1,pos"ITRF")
        pos3 = measure(frame,pos2,pos"WGS84")
        @test pos1.sys === pos3.sys === pos"WGS84"
        @test pos2.sys === pos"ITRF"
        @test pos1 ≈ pos3
        @test pos1 ≈ Position(pos"WGS84", 5000u"m", 20.5u"°", -80u"°")
        @test repr(pos1) == "5000.000 m, +20d30m00s, -80d00m00s"

        alma = observatory("ALMA")
        vla  = observatory("VLA")
        @test alma ≈ Position(pos"WGS84", 1.761867423e3, -4.307634996e3, -1.97770831e3)
        @test vla  ≈ Position(pos"ITRF", -1.601185365e6, -5.041977547e6,  3.55487587e6)
        @test_throws CasaCoreMeasuresError observatory("SKA")

        @test Measures.units(Position) == Measures.units(vla) == u"m"
    end

    @testset "baselines" begin
        @test baseline"ITRF"  === Measures.Baselines.ITRF
        @test baseline"J2000" === Measures.Baselines.J2000

        frame = ReferenceFrame()
        set!(frame, observatory("OVRO_MMA"))
        set!(frame, Epoch(epoch"UTC", 50237.29u"d"))
        set!(frame, Direction(dir"AZEL", 0u"°", 90u"°"))
        u, v, w = 1.234, 5.678, 0.100
        baseline1 = Baseline(baseline"ITRF", u, v, w)
        baseline2 = measure(frame,baseline1,baseline"J2000")
        baseline3 = measure(frame,baseline2,baseline"ITRF")
        @test baseline1.sys === baseline3.sys === baseline"ITRF"
        @test baseline2.sys === baseline"J2000"
        @test baseline1 ≈ baseline3
        @test repr(baseline1) == "1.234 meters, 5.678 meters, 0.100 meters"

        @test Measures.units(Baseline) == Measures.units(baseline1) == u"m"
    end

    @testset "conversions" begin
        itrf = (dir"ITRF", pos"ITRF", baseline"ITRF")
        not_itrf = (dir"J2000", pos"WGS84", baseline"GALACTIC")
        for sys in itrf
            @test sys == sys
            for sys′ in itrf
                @test sys == sys′
                @test sys′ == sys
            end
            for sys′ in not_itrf
                @test sys != sys′
                @test sys′ != sys
            end
        end
    end

    @testset "mathematics" begin
        x_position = Position(pos"ITRF", 2, 0, 0)
        y_position = Position(pos"ITRF", 0, 2, 0)
        z_position = Position(pos"ITRF", 0, 0, 2)
        x = Direction(x_position)
        y = Direction(y_position)
        z = Direction(z_position)

        @test cross(x, y) == z
        for lhs in (x, y, z), rhs in (x, y, z)
            if lhs == rhs
                @test dot(lhs, rhs) == 1
                @test Measures.angle_between(lhs, rhs) == 0*u"rad"
            else
                @test dot(lhs, rhs) == 0
                @test Measures.angle_between(lhs, rhs) == π/2*u"rad"
                @test Measures.gram_schmidt(lhs, rhs) == lhs
            end
        end

        @test cross(x, y_position) == z_position
        @test cross(x_position, y) == z_position
        @test dot(x, x_position) == 2*u"m"
        @test dot(x_position, x) == 2*u"m"
        for pos in (y_position, z_position)
            @test dot(x, pos) == 0*u"m"
            @test dot(pos, x) == 0*u"m"
        end

        @test x+y == Measures.UnnormalizedDirection(dir"ITRF", 1, 1, 0)
        @test 5*x == Measures.UnnormalizedDirection(dir"ITRF", 5, 0, 0)
        @test 2*x_position == Position(pos"ITRF", 4, 0, 0)
        @test 2*y_position == Position(pos"ITRF", 0, 4, 0)
        @test 2*z_position == Position(pos"ITRF", 0, 0, 4)
        @test x_position/2 == Position(pos"ITRF", 1, 0, 0)
        @test y_position/2 == Position(pos"ITRF", 0, 1, 0)
        @test z_position/2 == Position(pos"ITRF", 0, 0, 1)
        @test x_position + y_position - z_position == Position(pos"ITRF", 2, 2, -2)
    end
end

