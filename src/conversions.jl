immutable TpEnum{N}; end
const TpBool          =  0
const TpChar          =  1
const TpUChar         =  2
const TpShort         =  3
const TpUShort        =  4
const TpInt           =  5
const TpUInt          =  6
const TpFloat         =  7
const TpDouble        =  8
const TpComplex       =  9
const TpDComplex      = 10
const TpString        = 11
const TpTable         = 12
const TpArrayBool     = 13
const TpArrayChar     = 14
const TpArrayUChar    = 15
const TpArrayShort    = 16
const TpArrayUShort   = 17
const TpArrayInt      = 18
const TpArrayUInt     = 19
const TpArrayFloat    = 20
const TpArrayDouble   = 21
const TpArrayComplex  = 22
const TpArrayDComplex = 23
const TpArrayString   = 24
const TpRecord        = 25
const TpOther         = 26
const TpQuantity      = 27
const TpArrayQuantity = 28
const TpInt64         = 29
const TpArrayInt64    = 30
const TpNumberOfTypes = 31

@doc """
Map type strings to enumerate values
""" ->
const str2enum = Dict{UTF8String,Int}("bool"    => TpBool,
                                      "int"     => TpInt,
                                      "float"   => TpFloat,
                                      "double"  => TpDouble,
                                      "complex" => TpComplex,
                                      "string"  => TpString)

@doc """
Map type strings to Julia types.
""" ->
const str2type = Dict{UTF8String,Type}("bool"    => Bool,
                                       "int"     => Cint,
                                       "float"   => Cfloat,
                                       "double"  => Cdouble,
                                       "complex" => Complex{Cfloat})

@doc """
Map Julia types to Julia enumerate values.
""" ->
const type2enum = Dict{Type,Int}(Bool            => TpBool,
                                 Cint            => TpInt,
                                 Cfloat          => TpFloat,
                                 Cdouble         => TpDouble,
                                 Complex{Cfloat} => TpComplex)

