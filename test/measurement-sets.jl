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

@testset "Measurement Sets" begin

    @testset "creation" begin
        path = tempname()*".ms"
        ms = MeasurementSets.create(path)
        @test Tables.column_exists(ms, "UVW")
        @test Tables.column_exists(ms, "FLAG")
        @test Tables.column_exists(ms, "FLAG_CATEGORY")
        @test Tables.column_exists(ms, "WEIGHT")
        @test Tables.column_exists(ms, "SIGMA")
        @test Tables.column_exists(ms, "ANTENNA1")
        @test Tables.column_exists(ms, "ANTENNA2")
        @test Tables.column_exists(ms, "ARRAY_ID")
        @test Tables.column_exists(ms, "DATA_DESC_ID")
        @test Tables.column_exists(ms, "EXPOSURE")
        @test Tables.column_exists(ms, "FEED1")
        @test Tables.column_exists(ms, "FEED2")
        @test Tables.column_exists(ms, "FIELD_ID")
        @test Tables.column_exists(ms, "FLAG_ROW")
        @test Tables.column_exists(ms, "INTERVAL")
        @test Tables.column_exists(ms, "OBSERVATION_ID")
        @test Tables.column_exists(ms, "PROCESSOR_ID")
        @test Tables.column_exists(ms, "SCAN_NUMBER")
        @test Tables.column_exists(ms, "STATE_ID")
        @test Tables.column_exists(ms, "TIME")
        @test Tables.column_exists(ms, "TIME_CENTROID")
        @test ms[kw"MS_VERSION"] === Float32(2)
        @test Tables.keyword_exists(ms, kw"ANTENNA")
        @test Tables.keyword_exists(ms, kw"DATA_DESCRIPTION")
        @test Tables.keyword_exists(ms, kw"FEED")
        @test Tables.keyword_exists(ms, kw"FLAG_CMD")
        @test Tables.keyword_exists(ms, kw"FIELD")
        @test Tables.keyword_exists(ms, kw"HISTORY")
        @test Tables.keyword_exists(ms, kw"OBSERVATION")
        @test Tables.keyword_exists(ms, kw"POINTING")
        @test Tables.keyword_exists(ms, kw"POLARIZATION")
        @test Tables.keyword_exists(ms, kw"PROCESSOR")
        @test Tables.keyword_exists(ms, kw"SPECTRAL_WINDOW")
        @test Tables.keyword_exists(ms, kw"STATE")
        Tables.delete(ms)
    end

    @testset "reading / writing columns" begin
        path = tempname()*".ms"
        ms = MeasurementSets.create(path)
        Tables.add_rows!(ms, 5)

        uvw = randn(3, 5)
        ms["UVW"] = uvw
        @test ms["UVW"] == uvw
        @test_throws CasaCoreTablesError ms["UVW"] = randn(3, 4)
        @test_throws CasaCoreTablesError ms["UVW"] = randn(2, 5)

        weight = randn(Float32, 4, 5)
        ms["WEIGHT"] = weight
        @test ms["WEIGHT"] == weight

        Tables.delete(ms)
    end

end

