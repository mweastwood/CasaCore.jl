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

# Define methods for `get`ing and `put`ing of the
# ANTENNA1, and ANTENNA2 columns.
columns = ["ANTENNA1", "ANTENNA2"]
getfunc = [:getAntenna1,  :getAntenna2]
putfunc = [:putAntenna1!, :putAntenna2!]
for (col,getf,putf) in zip(columns,getfunc,putfunc)
    @eval begin
        @doc """
        Read the $col column from the given Measurement Set.
        """ ->
        function $getf(ms::MeasurementSet)
            ant = Array(Cint,numRows(ms.table))
            getColumn!(ant,ms.table,$col)
            ant + 1 # add one to convert to a 1-based indexing scheme
        end

        @doc """
        Write the $col column to the given Measurement Set.
        """ ->
        function $putf(ms::MeasurementSet,column::Vector{Cint})
            # subtract one to convert to a 0-based indexing scheme
            putColumn!(ms.table,$col,column-1)
        end
    end
end

@doc """
Read the UVW column from the given Measurement Set.
""" ->
function getUVW(ms::MeasurementSet)
    uvw = Array(Cdouble,3,numRows(ms.table))
    getColumn!(uvw,ms.table,"UVW")
    squeeze(uvw[1,:],1),squeeze(uvw[2,:],1),squeeze(uvw[3,:],1)
end

@doc """
Write the UVW column to the given Measurement Set.
""" ->
function putUVW!(ms::MeasurementSet,
                 u::Vector{Cdouble},
                 v::Vector{Cdouble},
                 w::Vector{Cdouble})
    putColumn!(ms.table,"UVW",hcat(u,v,w)')
end

@doc """
Read the CHAN_FREQ column from the given Measurement Set.
This requires opening the SPECTRAL_WINDOW subtable.
""" ->
function getFreq(ms::MeasurementSet)
    table_string = replace(getKeyword(ms.table,"SPECTRAL_WINDOW",ASCIIString),"Table: ","",1)
    table = Table(table_string)
    shape = getColumnShape(table,"CHAN_FREQ")
    freq  = Array(Cdouble,shape[1],shape[2])
    getColumn!(freq,table,"CHAN_FREQ")
    squeeze(freq,2)
end

@doc """
Write the CHAN_FREQ column to the given Measurement Set.
This requires opening the SPECTRAL_WINDOW subtable.
""" ->
function putFreq!(ms::MeasurementSet,freq::Vector{Cdouble})
    table_string = replace(getKeyword(ms.table,"SPECTRAL_WINDOW",ASCIIString),"Table: ","",1)
    table = Table(table_string)
    putColumn!(table,"CHAN_FREQ",reshape(freq,length(freq),1))
end

@doc """
Read the TIME column from the given Measurement Set.
""" ->
function getTime(ms::MeasurementSet)
    # TODO: Use column keywords to correctly map this to a measure?
    time = Array(Cdouble,numRows(ms.table))
    getColumn!(time,ms.table,"TIME")
    time
end

@doc """
Write the TIME column to the given Measurement Set.
""" ->
function putTime!(ms::MeasurementSet,time::Vector{Cdouble})
    putColumn!(ms.table,"TIME",time)
end

