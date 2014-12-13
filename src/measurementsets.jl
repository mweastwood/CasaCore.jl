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

