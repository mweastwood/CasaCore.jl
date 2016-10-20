# CasaCore.Tables

Load this module by running

``` julia
using CasaCore.Tables
```

The `Tables` module is used to interact with CasaCore tables. This is a common data format in radio
astronomy. For example CASA measurement sets and CASA calibration tables are simply CasaCore tables
with a standard set of columns, keywords, and subtables.

Opening a table is simple:

``` julia
table = Table("/path/to/table")
```

This will open an existing table at the given path, or create a new table if one does not already
exist at that path. Note that a read/write lock is automatically obtained on an open table. This
lock will automatically be released when the `table` object is garbage collected, but you may
manually release the lock by calling `Tables.unlock(table)`.

## Columns

Columns are accessed by name. For example to read the entire `DATA` column from a measurement set:

``` julia
table = Table("/path/to/measurementset.ms")
data = table["DATA"]
```

If we have some function `calibrate` that solves for and applies a calibration to the measured
visibilities, we can then write the calibrated data back to the `CORRECTED_DATA` column as follows:

``` julia
corrected_data = calibrate(data) # calibrate the measured visibilities
table["CORRECTED_DATA"] = corrected_data
```

Note that the `CORRECTED_DATA` column will be created in the table if it does not already exist. If
the column does already exist, the column will be overwritten with the contents of `corrected_data`.

!!! warning
    CasaCore.jl will throw a `CasaCoreError` exception if you try to overwrite a column with an
    array of the incorrect size or element type. A column that contains `float`s cannot be
    overwritten with an array of `int`s.

A column can be removed from the table by using `Tables.removecolumn!(table, "name")`, where
`"name"` is the name of the column to be removed from the table.

## Cells

If you do not want to read or write to an entire column, you can instead pick a single row of the
column (ie. a cell). For example, the length of the 123rd baseline in a measurement set can be
computed by:

``` julia
uvw = table["UVW", 123]
baseline_length = norm(uvw)
```

If we then perform a calculation that updates the `uvw` coordinates of this baseline, we can write
these changes back to the table:

``` julia
table["UVW", 123] = uvw
```

The number of rows in the table can be obtained with `Tables.numrows(table)`.  Note also that the
indexing order is column first, row second. This is opposite from the usual matrix convention where
the first index specifies the row.

!!! important
    Julia is 1-indexed programming language. This means that the first element of an array `x` is
    accessed with `x[1]` instead of `x[0]` (as is the case for C and Python). Similarly, the first
    row of a table is row number 1. Attempting to access row number 0 will throw a `CasaCoreError`
    because this row does not exist.

## Keywords

Keywords are accessed using the `kw"..."` string macro. For example:

``` julia
ms_version = table[kw"MS_VERSION"] # read the value of the "MS_VERSION" keyword
table[kw"MS_VERSION"] = 2.0        # set the value of the "MS_VERSION" keyword
```

A keyword can be removed with the `Tables.removekeyword!` function.

!!! warning
    A current known limitation of CasaCore.jl is the inability to read from or write to keywords
    that contain an array of values. This will be fixed if you file a bug report!

## Subtables

Subtables can be opened by reading their location from the appropriate keyword, and opening them as
you would a regular table.

``` julia
location = table[kw"SPECTRAL_WINDOW"]
subtable = Table(location)
```

In this example the `SPECTRAL_WINDOW` keyword contains the path to the corresponding subtable, which
usually contains information about the frequency bands and channels of a measurement set.

