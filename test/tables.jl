@testset "tables.jl" begin
    table_name = tempname()*".ms"
    table = Table(table_name)

    @test repr(table) == "Table: "*table_name

    #@test Tables.iswritable(table) == true
    #@test Tables.isreadable(table) == true

    @test Tables.numrows(table) == 0
    @test Tables.numcolumns(table) == 0
    @test Tables.numkeywords(table) == 0

    @testset "rows" begin
        Tables.addrows!(table, 20)
        @test Tables.numrows(table) == 20
        Tables.removerows!(table, 1:10)
        @test Tables.numrows(table) == 10
        Tables.removerows!(table, 1)
        @test Tables.numrows(table) == 9
        Tables.removerows!(table, [8, 9])
        @test Tables.numrows(table) == 7
        Tables.addrows!(table, 3)
        @test Tables.numrows(table) == 10
        Tables.removerows!(table, 1:10)
        @test Tables.numrows(table) == 0
    end

    Tables.addrows!(table, 10)

    @testset "columns" begin
        names = ("bools", "ints", "floats", "doubles", "complex", "strings")
        types = (Bool, Int32, Float32, Float64, Complex64, String)
        types_nostring = types[1:end-1]
        for shape in ((10,), (11, 10), (12, 11, 10))
            for (name, T) in zip(names, types)
                Tables.addcolumn!(table, name, T, shape)
                @test Tables.column_exists(table, name)
                @test Tables.column_eltype(table, name) == T
                @test Tables.column_dim(table, name) == length(shape)
                @test Tables.column_shape(table, name) == shape
            end
            @test Tables.numcolumns(table) == 6
            for name in names
                Tables.removecolumn!(table, name)
                @test !Tables.column_exists(table, name)
            end
            @test Tables.numcolumns(table) == 0
            for T in types_nostring
                x = rand(T, shape)
                y = length(shape) == 1? rand(T): rand(T, shape[1:end-1])
                z = length(shape) == 1? rand(Float16): rand(Float16, shape[1:end-1])
                table["test"] = x
                @test table["test"] == x
                @test_throws CasaCoreError table["test"] = rand(T, (6, 5)) # incorrect shape
                @test_throws CasaCoreError table["test"] = rand(Float16, shape) # incorrect type
                @test_throws CasaCoreError table["tset"] # typo
                table["test", 3] = y
                @test table["test", 3] == y
                @test_throws CasaCoreError table["tset",  3] = y # typo
                @test_throws CasaCoreError table["test",  0] = y # out-of-bounds
                @test_throws CasaCoreError table["test", 11] = y # out-of-bounds
                @test_throws CasaCoreError table["test",  3] = rand(T, (6, 5)) # incorrect shape
                @test_throws CasaCoreError table["test",  3] = z # incorrect type
                @test_throws CasaCoreError table["tset",  3] # typo
                @test_throws CasaCoreError table["test",  0] # out-of-bounds
                @test_throws CasaCoreError table["test", 11] # out-of-bounds
                Tables.removecolumn!(table, "test")
            end
            x = fill("Hello, world!", shape)
            y = length(shape) == 1? "Wassup??": fill("Wassup??", shape[1:end-1])
            z = length(shape) == 1? rand(Float16): rand(Float16, shape[1:end-1])
            table["test"] = x
            @test table["test"] == x
            @test_throws CasaCoreError table["test"] = fill("A", (6, 5)) # incorrect shape
            @test_throws CasaCoreError table["test"] = rand(Float16, shape) # incorrect type
            @test_throws CasaCoreError table["tset"] # typo
            table["test", 3] = y
            @test table["test", 3] == y
            @test_throws CasaCoreError table["tset",  3] = y # typo
            @test_throws CasaCoreError table["test",  0] = y # out-of-bounds
            @test_throws CasaCoreError table["test", 11] = y # out-of-bounds
            @test_throws CasaCoreError table["test",  3] = fill("A", (6, 5)) # incorrect shape
            @test_throws CasaCoreError table["test",  3] = z # incorrect type
            @test_throws CasaCoreError table["tset",  3] # typo
            @test_throws CasaCoreError table["test",  0] # out-of-bounds
            @test_throws CasaCoreError table["test", 11] # out-of-bounds
            Tables.removecolumn!(table, "test")
        end
    end

    @testset "keywords" begin
        for T in (Bool, Int32, Float32, Float64, Complex64)
            x = rand(T)
            table[kw"test"] = x
            @test table[kw"test"] == x
            @test_throws CasaCoreError table[kw"tset"] # typo
            @test_throws CasaCoreError table[kw"test"] = Float16(0) # incorrect type
            Tables.removekeyword!(table, kw"test")
        end
        x = "I am a banana!"
        table[kw"test"] = x
        @test table[kw"test"] == x
        @test_throws CasaCoreError table[kw"tset"] # typo
        @test_throws CasaCoreError table[kw"test"] = Float16(0) # incorrect type
        Tables.removekeyword!(table, kw"test")
    end

    @testset "column keywords" begin
        Tables.addcolumn!(table, "column", Float64, (10,))
        for T in (Bool, Int32, Float32, Float64, Complex64)
            x = rand(T)
            table["column", kw"test"] = x
            @test table["column", kw"test"] == x
            @test_throws CasaCoreError table["column", kw"tset"] # typo
            @test_throws CasaCoreError table["column", kw"test"] = Float16(0) # incorrect type
            Tables.removekeyword!(table, "column", kw"test")
        end
        x = "I am a banana!"
        table["column", kw"test"] = x
        @test table["column", kw"test"] == x
        @test_throws CasaCoreError table["colunm", kw"test"] # typo
        @test_throws CasaCoreError table["column", kw"tset"] # typo
        @test_throws CasaCoreError table["colunm", kw"test"] = x # typo
        @test_throws CasaCoreError table["column", kw"test"] = Float16(0) # incorrect type
        Tables.removekeyword!(table, "column", kw"test")
        Tables.removecolumn!(table, "column")
    end

    @testset "old tests" begin
        @test Tables.column_exists(table,"SKA_DATA") == false
        table["SKA_DATA"] = ones(10)
        @test Tables.column_exists(table,"SKA_DATA") == true
        Tables.removecolumn!(table,"SKA_DATA")
        @test Tables.column_exists(table,"SKA_DATA") == false

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
        @test Tables.column_exists(table,"ANTENNA1") == true
        @test Tables.column_exists(table,"ANTENNA2") == true
        @test Tables.column_exists(table,"UVW")      == true
        @test Tables.column_exists(table,"TIME")     == true
        @test Tables.column_exists(table,"DATA")            == true
        @test Tables.column_exists(table,"MODEL_DATA")      == true
        @test Tables.column_exists(table,"CORRECTED_DATA")  == true
        @test Tables.column_exists(table,"FABRICATED_DATA") == false

        @test table["ANTENNA1"] == ant1
        @test table["ANTENNA2"] == ant2
        @test table["UVW"]      == uvw
        @test table["TIME"]     == time
        @test table["DATA"]           == data
        @test table["MODEL_DATA"]     == model
        @test table["CORRECTED_DATA"] == corrected
        @test_throws CasaCoreError table["FABRICATED_DATA"]

        @test table["ANTENNA1",1] == ant1[1]
        @test table["ANTENNA2",1] == ant2[1]
        @test table["UVW",1]      == uvw[:,1]
        @test table["TIME",1]     == time[1]
        @test table["DATA",1]           == data[:,:,1]
        @test table["MODEL_DATA",1]     == model[:,:,1]
        @test table["CORRECTED_DATA",1] == corrected[:,:,1]
        @test_throws CasaCoreError table["FABRICATED_DATA",1]

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
        @test_throws CasaCoreError table["FABRICATED_DATA",1] = 1

        @test table["ANTENNA1",1] == ant1[1]
        @test table["ANTENNA2",1] == ant2[1]
        @test table["UVW",1]      == uvw[:,1]
        @test table["TIME",1]     == time[1]
        @test table["DATA",1]           == data[:,:,1]
        @test table["MODEL_DATA",1]     == model[:,:,1]
        @test table["CORRECTED_DATA",1] == corrected[:,:,1]
        @test_throws CasaCoreError table["FABRICATED_DATA",1]

        # Fully populate the columns again for the test where the
        # table is opened again
        table["ANTENNA1"] = ant1
        table["ANTENNA2"] = ant2
        table["UVW"]      = uvw
        table["TIME"]     = time
        table["DATA"]           = data
        table["MODEL_DATA"]     = model
        table["CORRECTED_DATA"] = corrected

        subtable = Table("$table_name/SPECTRAL_WINDOW")
        Tables.addrows!(subtable,1)
        subtable["CHAN_FREQ"] = freq
        @test subtable["CHAN_FREQ"] == freq
        finalize(subtable)

        @test Tables.numkeywords(table) == 0
        table[kw"SPECTRAL_WINDOW"] = "Table: $table_name/SPECTRAL_WINDOW"
        @test Tables.numkeywords(table) == 1
        @test table[kw"SPECTRAL_WINDOW"] == "Table: $table_name/SPECTRAL_WINDOW"

        table["DATA",kw"Hello,"] = "World!"
        @test table["DATA",kw"Hello,"] == "World!"
        table[kw"MICHAEL_IS_COOL"] = true
        @test table[kw"MICHAEL_IS_COOL"] == true
        table[kw"PI"] = 3.14159
        @test table[kw"PI"] == 3.14159

        @test_throws CasaCoreError table[kw"BOBBY_TABLES"]
        @test_throws CasaCoreError table["DATA",kw"SYSTEMATIC_ERRORS"]
        @test_throws CasaCoreError table["SKA_DATA",kw"SCHEDULE"]

        # Try locking and unlocking the table
        Tables.unlock(table)
        Tables.lock(table)
        Tables.unlock(table)

        # Test opening the table again
        table′ = Table(table_name)
        @test table["ANTENNA1"] == ant1
        @test table["ANTENNA2"] == ant2
        @test table["UVW"]      == uvw
        @test table["TIME"]     == time
        @test table["DATA"]           == data
        @test table["MODEL_DATA"]     == model
        @test table["CORRECTED_DATA"] == corrected
        @test_throws CasaCoreError table["FABRICATED_DATA"]
    end

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
        Tables.unlock(table) # forces the write to disk
        Tables.lock(table)
        rr = RemoteChannel()
        @async put!(rr, remotecall_fetch(load_and_read, 2, name))
        for i = 1:3
            sleep(1)
            @test !isready(rr)
        end
        Tables.unlock(table)
        @test fetch(rr) == ([1.0], 1.0)
    end

    # Issue #58
    # This will create a temporary table in the user's home directory so only run this test if we
    # are running tests from a CI service
    if get(ENV, "CI", "false") == "true"
        println("Running test for issue #58")
        ms1 = Table("~/issue58.ms")
        Tables.addrows!(ms1, 1)
        ms1["col"] = [1.0]
        unlock(ms1)
        ms2 = Table("~/issue58.ms")
        @test ms2["col"] == [1.0]
    end
end

