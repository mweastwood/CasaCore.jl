@testset "Table Tests" begin
    name  = tempname()*".ms"
    table = Table(name)

    @test repr(table) == "Table: "*name
    @test Tables.iswritable(table) == true
    @test Tables.isreadable(table) == true

    Tables.addrows!(table,10)
    @test Tables.numrows(table) == 10

    @test Tables.exists(table,"SKA_DATA") == false
    table["SKA_DATA"] = ones(10)
    @test Tables.exists(table,"SKA_DATA") == true
    Tables.delete!(table,"SKA_DATA")
    @test Tables.exists(table,"SKA_DATA") == false

    ant1 = Array(Int32,10)
    ant2 = Array(Int32,10)
    uvw  = Array(Float64,3,10)
    time = Array(Float64,10)
    data      = Array(Complex64,4,109,10)
    model     = Array(Complex64,4,109,10)
    corrected = Array(Complex64,4,109,10)
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

    @test Tables.numcolumns(table) == 7
    @test size(table) == (10,7)
    @test Tables.exists(table,"ANTENNA1") == true
    @test Tables.exists(table,"ANTENNA2") == true
    @test Tables.exists(table,"UVW")      == true
    @test Tables.exists(table,"TIME")     == true
    @test Tables.exists(table,"DATA")            == true
    @test Tables.exists(table,"MODEL_DATA")      == true
    @test Tables.exists(table,"CORRECTED_DATA")  == true
    @test Tables.exists(table,"FABRICATED_DATA") == false

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
    @test_throws ErrorException table["FABRICATED_DATA",1] = 1

    @test table["ANTENNA1",1] == ant1[1]
    @test table["ANTENNA2",1] == ant2[1]
    @test table["UVW",1]      == uvw[:,1]
    @test table["TIME",1]     == time[1]
    @test table["DATA",1]           == data[:,:,1]
    @test table["MODEL_DATA",1]     == model[:,:,1]
    @test table["CORRECTED_DATA",1] == corrected[:,:,1]
    @test_throws ErrorException table["FABRICATED_DATA",1]

    # Fully populate the columns again for the test where the
    # table is opened again
    table["ANTENNA1"] = ant1
    table["ANTENNA2"] = ant2
    table["UVW"]      = uvw
    table["TIME"]     = time
    table["DATA"]           = data
    table["MODEL_DATA"]     = model
    table["CORRECTED_DATA"] = corrected

    subtable = Table("$name/SPECTRAL_WINDOW")
    Tables.addrows!(subtable,1)
    subtable["CHAN_FREQ"] = freq
    @test subtable["CHAN_FREQ"] == freq
    finalize(subtable)

    @test Tables.numkeywords(table) == 0
    table[kw"SPECTRAL_WINDOW"] = "Table: $name/SPECTRAL_WINDOW"
    @test Tables.numkeywords(table) == 1
    @test table[kw"SPECTRAL_WINDOW"] == "Table: $name/SPECTRAL_WINDOW"

    table["DATA",kw"Hello,"] = "World!"
    @test table["DATA",kw"Hello,"] == "World!"
    table[kw"MICHAEL_IS_COOL"] = true
    @test table[kw"MICHAEL_IS_COOL"] == true
    table[kw"PI"] = 3.14159
    @test table[kw"PI"] == 3.14159

    @test_throws ErrorException table[kw"BOBBY_TABLES"]
    @test_throws ErrorException table["DATA",kw"SYSTEMATIC_ERRORS"]
    @test_throws ErrorException table["SKA_DATA",kw"SCHEDULE"]

    # Try locking and unlocking the table
    unlock(table)
    lock(table)
    unlock(table)

    # Test opening the table again
    table′ = Table(name)
    @test table["ANTENNA1"] == ant1
    @test table["ANTENNA2"] == ant2
    @test table["UVW"]      == uvw
    @test table["TIME"]     == time
    @test table["DATA"]           == data
    @test table["MODEL_DATA"]     == model
    @test table["CORRECTED_DATA"] == corrected
    @test_throws ErrorException table["FABRICATED_DATA"]

    @testset "locks" begin
        # a lock will guard against another process accessing
        # the table, so let's use a worker to try and access
        # a locked table
        name = tempname()*".ms"
        table = Table(name)
        Tables.addrows!(table, 1)
        table["COLUMN"] = [1.0]
        @everywhere function load_and_read(name)
            mytable = CasaCore.Tables.Table(name)
            mytable["COLUMN"], mytable["COLUMN",1]
        end
        unlock(table) # forces the write to disk
        lock(table)
        rr = RemoteChannel()
        @async put!(rr, remotecall_fetch(load_and_read, 2, name))
        for i = 1:3
            sleep(1)
            @test !isready(rr)
        end
        unlock(table)
        @test fetch(rr) == ([1.0], 1.0)
    end
end

