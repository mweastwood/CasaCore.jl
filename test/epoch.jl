let
    @test epoch"UTC" === Measures.Epochs.UTC
    @test epoch"LAST" === Measures.Epochs.LAST
end

let
    frame = ReferenceFrame()

    date = 50237.29
    time = Epoch(epoch"UTC",Quantity(date,"d"))
    @test coordinate_system(time) === epoch"UTC"
    @test days(time) == date
    @test seconds(time) == date*24*60*60
    @test repr(time) == "$date days"

    tai = Epoch(epoch"TAI",Quantity(date,"d"))
    @test coordinate_system(tai) === epoch"TAI"
    @test days(time) == date
    @test seconds(time) == date*24*60*60

    utc = measure(frame,tai,epoch"UTC")
    @test coordinate_system(utc) === epoch"UTC"
    tai_again = measure(frame,utc,epoch"TAI")
    @test coordinate_system(tai_again) === epoch"TAI"
    @test days(tai_again) == date
end

