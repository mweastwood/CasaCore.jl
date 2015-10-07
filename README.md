# CasaCore

[![Build Status](https://travis-ci.org/mweastwood/CasaCore.jl.svg?branch=master)](https://travis-ci.org/mweastwood/CasaCore.jl)
[![Coverage Status](https://img.shields.io/codecov/c/github/mweastwood/CasaCore.jl.svg)](https://codecov.io/github/mweastwood/CasaCore.jl)
[![License](https://img.shields.io/badge/license-GPLv3%2B-blue.svg)](LICENSE.md)

## Getting Started

To get started using CasaCore, run:
```julia
Pkg.add("CasaCore")
Pkg.test("CasaCore")
```
The build process does not attempt to install [CasaCore](http://casacore.github.io/casacore/). This must be done prior to using this package.

## Measures

```julia
using CasaCore.Measures
```
To use the the measures module of CasaCore, you first need to define a reference frame:
```julia
frame = ReferenceFrame()
position = observatory("OVRO_MMA")
time = Epoch(epoch"UTC",Quantity(50237.29,Unit("d")))
set!(frame,position)
set!(frame,time)
```
After the reference frame is defined, you can convert between various coordinate systems:
```julia
j2000 = Direction(dir"J2000",ra"19h59m28.35663s",dec"+40d44m02.0970s")
azel  = measure(frame,j2000,dir"AZEL")
```

## Tables

```julia
using CasaCore.Tables
```
Interacting with CasaCore tables requires you to first open the table:
```julia
table = Table("/path/to/table")
```
Then you can read and write columns of the table as follows:
```julia
data = table["DATA"] # type-unstable (see below)
modeldata = function_to_gen_model_visibilities()
table["MODEL_DATA"] = modeldata
```
You can read and write cells in a similar manner:
```julia
row = 1 # Note that rows are numbered starting from 1
cell = table["DATA",row] # type-unstable (see below)
table["MODEL_DATA",row] = newcell
```
Finally, keywords are accessed using the `kw"..."` string macro. For example:
```julia
spw = table[kw"SPECTRAL_WINDOW"]
table[kw"SPECTRAL_WINDOW"] = newspw
```

Note that reading a column (or a cell) is necessarily type-unstable. That is, the element type and shape of the
column cannot be inferred from the types of the arguments. You can mitigate this issue by adding a type annotation
or by separating the computational kernel
(see the [Performance Tips](http://julia.readthedocs.org/en/latest/manual/performance-tips/#separate-kernel-functions) section of the manual).

## Development

At the moment, the functionality of this package is largely focused on my own requirements. If you need additional
features, open an issue or a pull request. In the short term, you can use the excellent
[PyCall](https://github.com/stevengj/PyCall.jl) package to access the Python wrapper of CasaCore ([pyrap](https://code.google.com/p/pyrap/)).

