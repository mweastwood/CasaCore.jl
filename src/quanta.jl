type Quantity{T<:FloatingPoint,S<:String}
    value::T
    unit::S
end

Quantity(record::CasaRecord) = Quantity(record["value"],record["unit"])

@doc """
This macro constructs a Quantity from a string.
    
# Examples
* q"1234.5s" → Quantity(1234.5,"s")
* q"1.23e4s" → Quantity(1.23e4,"s")
* q"1.23rad" → Quantity(1.23,"rad")
""" ->
macro q_str(string)
    regex   = r"([0-9]+\.?[0-9]*e?[0-9]*)([A-Za-z]+)"
    substrs = match(regex,string).captures
    Quantity(float(substrs[1]),ASCIIString(substrs[2]))
end

function show(io::IO,quantity::Quantity)
    print(io,"$(quantity.value) $(quantity.unit)")
end

