# CasaCore

[![Build Status](https://travis-ci.org/mweastwood/CasaCore.jl.svg?branch=master)](https://travis-ci.org/mweastwood/CasaCore.jl)
[![Coverage Status](https://img.shields.io/coveralls/mweastwood/CasaCore.jl.svg?style=flat)](https://coveralls.io/r/mweastwood/CasaCore.jl?branch=master)

## Getting Started

CasaCore is currently an unregistered package. Therefore, to get started using CasaCore, run:
```julia
Pkg.clone("https://github.com/mweastwood/CasaCore.jl.git")
Pkg.build("CasaCore")
Pkg.test("CasaCore")
using CasaCore
```
The build process will attempt to download, build, and install [CasaCore](https://code.google.com/p/casacore/) if it does not already exist on your system.

## Measures

To use the the measures module of CasaCore, you first need to define a reference frame:
```julia
frame = ReferenceFrame()
position = observatory(frame,"OVRO_MMA")
time = Epoch("UTC",q"4.905577293531662e9s")
set!(frame,position)
set!(frame,time)
```
After the reference frame is defined, you can convert between various coordinate systems:
```julia
dir   = Direction("AZEL",q"0.0rad",q"1.0rad")
j2000 = measure(frame,"J2000",dir)
```

## Tables

Interacting with CasaCore tables requires you to first open the table:
```julia
table = Table("/path/to/table")
```
Then you can add/remove/write to/read from columns and rows of the table as follows:
```julia
addScalarColumn!(table,"ANTENNA1",Int32)
addArrayColumn!(table,"MODEL_DATA",Complex64,[4,109])
addRows!(table,10)
removeRows!(table,[6:10])
modeldata = function_to_gen_model_visibilities()
putColumn!(table,"MODEL_DATA",modeldata)
modeldata = getColumn(table,"MODEL_DATA") # type-unstable!
```
Note that `getColumn` is necessarily type-unstable. That is, the return type of `getColumn` cannot be inferred from the types of the arguments. If you have prior knowledge of what is stored in the column, you can mitigate this issue with one of two solutions:

1. Adding a type annotation
2. Using `getColumn!`

For example, write
```julia
modeldata = getColumn(table,"MODEL_DATA")::Array{Complex64,3}
# or
getColumn!(modeldata,table,"MODEL_DATA")
```

### Measurement Sets

A convenience interface for interacting with [CASA Measurement Sets](http://casa.nrao.edu/Memos/229.html) can be used by using the `MeasurementSet` type:
```julia
ms = MeasurementSet("/path/to/measurementset.ms")
data = getData(ms)
modeldata = function_to_gen_model_visibilities()
putModelData!(ms,modeldata)
```

## Development

At the moment, the functionality of this package is largely focused on my own requirements. If you need additional features, open an issue or a pull request. In the short term, you can use the excellent [PyCall](https://github.com/stevengj/PyCall.jl) package to access the Python wrapper of CasaCore ([pyrap](https://code.google.com/p/pyrap/)).
