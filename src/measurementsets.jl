@doc """
Define a more convenient interface for dealing with
Casa Measurement Sets.
""" ->
type MeasurementSet
    table::Table
    cache::Dict{ASCIIString,Array{Complex64,3}}
end

function MeasurementSet(name::String)
    MeasurementSet(Table(name),Dict{ASCIIString,Complex64}())
end

getColumn (ms::MeasurementSet,name::String) = getColumn(ms.table,name)
putColumn!(ms::MeasurementSet,name::String,data) = putColumn!(ms.table,name,data)

# Define methods for `get`ing and `put`ing of the
# DATA, MODEL_DATA, and CORRECTED_DATA columns.
columns = ["DATA", "MODEL_DATA", "CORRECTED_DATA"]
getfunc = [:getData,  :getModelData,  :getCorrectedData]
putfunc = [:putData!, :putModelData!, :putCorrectedData!]
for (col,getf,putf) in zip(columns,getfunc,putfunc)
    @eval begin
        @doc """
        Read the $col column from the given Measurement Set.
        Note that this operation will be cached.
        """ ->
        function $getf(ms::MeasurementSet)
            if !haskey(ms.cache,$col)
                ms.cache[$col] = getColumn(ms,$col)
            end
            ms.cache[$col]
        end

        @doc """
        Write the $col column to the given Measurement Set.
        Note that this operation will be cached.
        """ ->
        function $putf(ms::MeasurementSet,column::Array{Complex64,3})
            ms.cache[$col] = column
            putColumn!(ms,$col,column)
        end
    end
end

columns = ["ANTENNA1", "ANTENNA2"]
getfunc = [:getAntenna1, :getAntenna2]
for (col,getf) in zip(columns,getfunc)
    @eval begin
        function $getf(ms::MeasurementSet)
            # Add one to convert to a 1-based indexing scheme
            getColumn(ms,$col) + 1
        end
    end
end

function getUVW(ms::MeasurementSet)
    uvw = getColumn(ms,"UVW")
    uvw[1,:],uvw[2,:],uvw[3,:]
end

function getFreq(ms::MeasurementSet)
    table_string = replace(getKeyword_string(ms.table,"SPECTRAL_WINDOW"),"Table: ","",1)
    table = Table(table_string)
    squeeze(getColumn(table,"CHAN_FREQ"),2)
end

function getTime(ms::MeasurementSet)
    # TODO: rewrite this with getCell instead
    Epoch("UTC",Quantity(getColumn(ms,"TIME")[1],"s"))
end

