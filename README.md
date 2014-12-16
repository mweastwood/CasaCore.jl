# CasaCore

[![Build Status](https://travis-ci.org/mweastwood/CasaCore.jl.svg?branch=master)](https://travis-ci.org/mweastwood/CasaCore.jl)

## Measures

To use the the measures module of CasaCore, you first need to define a reference frame:
```
frame = ReferenceFrame()
position = observatory(frame,"OVRO_MMA")
time = Epoch("UTC",q"4.905577293531662e9s")
set!(frame,position)
set!(frame,time)
```
After the reference frame is defined, you can convert between various coordinate systems:
```
dir   = Direction("AZEL",q"0.0rad",q"1.0rad")
j2000 = measure(frame,"J2000",dir)
```

## Tables

Interacting with CasaCore tables requires you to first open the  table:
```
table = Table("/path/to/table")
```
Then you can add/remove/write to/read from columns and rows of the table as follows:
```
addScalarColumn!(table,"ANTENNA1","int")
addScalarColumn!(table,"ANTENNA2","int")
addRows!(table,10)
removeRows!(table,[6:10])
```

## Development

At the moment, the functionality of this package is largely focused on my own requirements. If you need additional features, open an issue or a pull request. In the short term, you can use the excellent `PyCall` package to access the Python wrapper of CasaCore (`pyrap`).
