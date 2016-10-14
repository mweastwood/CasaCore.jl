@testset "Table Tests" begin
    name  = tempname()*".ms"
    table = Table(name)

    @test repr(table) == "Table: "*name

    #@test Tables.iswritable(table) == true
    #@test Tables.isreadable(table) == true

    @test Tables.numrows(table) == 0
    @test Tables.numcolumns(table) == 0

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

    for shape in ((10,), (11, 10), (12, 11, 10))
        Tables.create_column!(table, "bools", Bool, shape)
        Tables.create_column!(table, "ints", Int32, shape)
        Tables.create_column!(table, "floats", Float32, shape)
        Tables.create_column!(table, "doubles", Float64, shape)
        Tables.create_column!(table, "complex", Complex64, shape)
        Tables.create_column!(table, "strings", String, shape)
        @test Tables.numcolumns(table) == 6
        @test Tables.column_eltype(table, "bools") == Bool
        @test Tables.column_eltype(table, "ints") == Int32
        @test Tables.column_eltype(table, "floats") == Float32
        @test Tables.column_eltype(table, "doubles") == Float64
        @test Tables.column_eltype(table, "complex") == Complex64
        @test Tables.column_eltype(table, "strings") == String
        @test Tables.column_dim(table, "bools") == length(shape)
        @test Tables.column_dim(table, "ints") == length(shape)
        @test Tables.column_dim(table, "floats") == length(shape)
        @test Tables.column_dim(table, "doubles") == length(shape)
        @test Tables.column_dim(table, "complex") == length(shape)
        @test Tables.column_dim(table, "strings") == length(shape)
        @test Tables.column_shape(table, "bools") == shape
        @test Tables.column_shape(table, "ints") == shape
        @test Tables.column_shape(table, "floats") == shape
        @test Tables.column_shape(table, "doubles") == shape
        @test Tables.column_shape(table, "complex") == shape
        @test Tables.column_shape(table, "strings") == shape
        @test Tables.column_exists(table, "bools")
        @test Tables.column_exists(table, "ints")
        @test Tables.column_exists(table, "floats")
        @test Tables.column_exists(table, "doubles")
        @test Tables.column_exists(table, "complex")
        @test Tables.column_exists(table, "strings")
        Tables.removecolumn!(table, "bools")
        Tables.removecolumn!(table, "ints")
        Tables.removecolumn!(table, "floats")
        Tables.removecolumn!(table, "doubles")
        Tables.removecolumn!(table, "complex")
        Tables.removecolumn!(table, "strings")
        @test !Tables.column_exists(table, "bools")
        @test !Tables.column_exists(table, "ints")
        @test !Tables.column_exists(table, "floats")
        @test !Tables.column_exists(table, "doubles")
        @test !Tables.column_exists(table, "complex")
        @test !Tables.column_exists(table, "strings")
        @test Tables.numcolumns(table) == 0
        for T in (Bool, Int32, Float32, Float64, Complex64, String)
            if T == String
                x = fill("Hello, world!", shape)
                x1 = fill("Wassup??", (6, 5))
                x2 = rand(Float16, shape)
                if length(shape) == 1
                    y = "Michael is pretty neat."
                else
                    y = fill("Michael is pretty neat.", shape[1:end-1])
                end
                y1 = fill("Wassup??", (6, 5))
                y2 = rand(Float16, shape[1:end-1])
            else
                x = rand(T, shape)
                x1 = rand(T, (6, 5))
                x2 = rand(Float16, shape)
                if length(shape) == 1
                    y = rand(T)
                else
                    y = rand(T, shape[1:end-1])
                end
                y1 = rand(T, (6, 5))
                y2 = rand(Float16, shape[1:end-1])
            end
            table["test"] = x
            @test table["test"] == x
            @test_throws CasaCoreError table["test"] = x1
            @test_throws CasaCoreError table["test"] = x2
            @test_throws CasaCoreError table["tset"]
            table["test", 3] = y
            @test table["test", 3] == y
            @test_throws CasaCoreError table["tset",  3] = y
            @test_throws CasaCoreError table["test",  0] = y
            @test_throws CasaCoreError table["test", 11] = y
            @test_throws CasaCoreError table["test",  3] = y1
            @test_throws CasaCoreError table["test",  3] = y2
            @test_throws CasaCoreError table["tset",  3]
            @test_throws CasaCoreError table["test",  0]
            @test_throws CasaCoreError table["test", 11]
            Tables.removecolumn!(table, "test")
        end
    end

    @testset "keywords" begin
        for T in (Bool, Int32, Float32, Float64, Complex64)
            x = rand(T)
            table[kw"test"] = x
            @test table[kw"test"] == x
        end
    end

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

    #=
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
    =#
end

