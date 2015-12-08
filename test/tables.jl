@testset "Table Tests" begin
    name  = tempname()*".ms"
    table = Table(name)

    @test Tables.iswritable(table) == true
    @test Tables.isreadable(table) == true

    Tables.addRows!(table,10)
    @test numrows(table) == 10
    Tables.removeRows!(table,[6:10;])
    @test numrows(table) ==  5

    @test Tables.checkColumnExists(table,"SKA_DATA") == false
    table["SKA_DATA"] = ones(5)
    @test Tables.checkColumnExists(table,"SKA_DATA") == true
    Tables.removeColumn!(table,"SKA_DATA")
    @test Tables.checkColumnExists(table,"SKA_DATA") == false

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
    @test size(table) == (5,7)
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

    table[kw"MICHAEL_IS_COOL"] = true
    @test table[kw"MICHAEL_IS_COOL"] == true

    table[kw"PI"] = 3.14159
    @test table[kw"PI"] == 3.14159

    # Try locking and unlocking the table
    unlock(table)
    lock(table)
    unlock(table)
end

