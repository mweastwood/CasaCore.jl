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
                ms.cache[$col] = getColumn(ms.table,$col)
            end
            ms.cache[$col]
        end

        @doc """
        Write the $col column to the given Measurement Set.
        Note that this operation will be cached.
        """ ->
        function $putf(ms::MeasurementSet,column::Array{Complex64,3})
            ms.cache[$col] = column
            putColumn!(ms.table,$col,column)
        end
    end
end

columns = ["ANTENNA1", "ANTENNA2"]
getfunc = [:getAntenna1, :getAntenna2]
for (col,getf) in zip(columns,getfunc)
    @eval begin
        function $getf(ms::MeasurementSet)
            ant = Array(Cint,nrows(ms.table))
            getColumn!(ant,ms.table,$col)
            ant + 1 # add one to convert to a 1-based indexing scheme
        end
    end
end

function getUVW(ms::MeasurementSet)
    uvw = Array(Cdouble,3,nrows(ms.table))
    getColumn!(uvw,ms.table,"UVW")
    uvw[1,:],uvw[2,:],uvw[3,:]
end

function getFreq(ms::MeasurementSet)
    table_string = replace(getKeyword(ms.table,"SPECTRAL_WINDOW",ASCIIString),"Table: ","",1)
    table = Table(table_string)
    shape = getColumnShape(table,"CHAN_FREQ")
    freq  = Array(Cdouble,shape[1],shape[2])
    getColumn!(freq,table,"CHAN_FREQ")
    squeeze(freq,2)
end

function getTime(ms::MeasurementSet)
    # TODO: rewrite this with getCell instead
    Epoch("UTC",Quantity(getColumn(ms.table,"TIME")[1],"s"))
end

