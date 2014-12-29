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

const type2str = Dict{Type,ASCIIString}()
const str2type = Dict{ASCIIString,Type}()
const type2enum = Dict{Type,Int}()
const enum2type = Dict{Int,Type}()

for (T,str,enum) in ((Bool,"bool",TpBool),
                     (Int32,"int",TpInt),
                     (Float32,"float",TpFloat),
                     (Float64,"double",TpDouble),
                     (Complex64,"complex",TpComplex),
                     (ASCIIString,"string",TpString))
    type2str[T] = str
    str2type[str] = T
    type2enum[T] = enum
    enum2type[enum] = T
end

