# CasaCore.jl

CasaCore.jl is a Julia wrapper of [CasaCore](http://casacore.github.io/casacore/), which is a
commonly used library in radio astronomy.

Functionality is divided into two submodules:

* `CasaCore.Tables` for interfacing with tables (for example Casa measurement sets), and
* `CasaCore.Measures` for performing coordinate system conversions (for example calculating the
  azimuth and elevation of an astronomical target).

## Getting Started

Prior to using this package, the CasaCore library must be installed on your machine. The header and
shared library files must either be located in a standard location or the corresponding directories
must be added to the appropriate system path environment variable.

Additionally you must also have v0.5 of the Julia programming language. CasaCore.jl makes use of
features that are not present in v0.4 or lower. Download and install the latest version of Julia
from [the Julia language website](http://julialang.org/).

Finally you may obtain CasaCore.jl by running (from within the Julia REPL):
```julia
Pkg.add("CasaCore")  # download CasaCore.jl and attempt to build the wrapper
Pkg.test("CasaCore") # test that CasaCore.jl is working properly
```

If `Pkg.add("CasaCore")` fails with a build error, you may need to make sure that the CasaCore
libraries are installed and can be found by your C++ compiler. You can attempt to re-build the
CasaCore.jl wrapper by running `Pkg.build("CasaCore")`, but this is only necessary if the first
attempt failed.

If CasaCore.jl was built successfully but any (or all) of the tests fail after running
`Pkg.test("CasaCore")`, please open a Github issue.

## Bugs and Feature Requests

Development of this package is ongoing and largely focused on my own requirements.  If you need
additional features, open an issue or a pull request.  In the short term, you can use the excellent
[PyCall](https://github.com/stevengj/PyCall.jl) package to access the Python wrapper of CasaCore
([python-casacore](https://github.com/casacore/python-casacore)).

