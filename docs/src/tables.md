# CasaCore.Tables

```@meta
CurrentModule = CasaCore.Tables
DocTestSetup = quote
    using CasaCore.Tables
end
```

Load this module by running

```julia
using CasaCore.Tables
```

The `Tables` module is used to interact with CasaCore tables. This is a common data format in radio
astronomy. For example CASA measurement sets and CASA calibration tables are simply CasaCore tables
with a standard set of columns, keywords, and subtables.

## Tables

```@docs
Table
Tables.create
Tables.open
Tables.close
Tables.delete
Tables.num_rows
Tables.add_rows!
Tables.remove_rows!
```

## Columns

Columns are accessed by name. Some common table names (used in CASA measurement sets) are `UVW` (the
baseline coordinates), `DATA` (the uncalibrated data), and `CORRECTED_DATA` (the calibrated data).

For example to read and write the entire `DATA` column from a measurement set:

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
       Tables.add_rows!(table, 100)
       Npol  =   4 # number of polarizations
       Nfreq =  50 # number of frequency channels
       Nbase = 100 # number of baselines
       data = rand(Complex64, Npol, Nfreq, Nbase)
       table["DATA"] = data # creates the DATA column if it doesn't already exist
       data == table["DATA"]
true

julia> Tables.delete(table)
```

!!! warning
    CasaCore.jl will throw a `CasaCoreTablesError` exception if you try to overwrite a column with
    an array of the incorrect size or element type. A column that contains `float`s cannot be
    overwritten with an array of `int`s.

```@docs
Tables.num_columns
Tables.remove_column!
```

## Cells

If you do not want to read or write to an entire column, you can instead pick a single row of the
column (ie. a cell). For example, the length of the 123rd baseline in a measurement set can be
computed by:

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
       Nbase = 500 # number of baselines
       Tables.add_rows!(table, 500)
       uvw = 100 .* randn(3, Nbase) # create a random set of baselines
       table["UVW"] = uvw # creates the UVW column if it doesn't already exist
       uvw[:, 123] == table["UVW", 123]
true

julia> table["UVW", 123] = [100., 50, 0.]
       table["UVW", 123]
3-element Array{Float64,1}:
 100.0
  50.0
   0.0

julia> Tables.delete(table)
```

The number of rows in the table can be obtained with [`Tables.num_rows`](@ref).  Note also that the
indexing order is column first, row second. This is opposite from the usual matrix convention where
the first index specifies the row.

!!! important
    Julia is 1-indexed programming language. This means that the first element of an array `x` is
    accessed with `x[1]` instead of `x[0]` (as is the case for C and Python). Similarly, the first
    row of a table is row number 1. Attempting to access row number 0 will throw a
    `CasaCoreTablesError` because this row does not exist.

## Keywords

Keywords are accessed using the `kw"..."` string macro. For example:

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
       table[kw"MS_VERSION"] = 2.0 # set the value of the "MS_VERSION" keyword
       table[kw"MS_VERSION"]       # read the value of the "MS_VERSION" keyword
2.0

julia> Tables.delete(table)
```

```@docs
Tables.num_keywords
Tables.remove_keyword!
```

## Subtables

Subtables will be automatically opened by reading the appropriate keyword. These tables need to be
closed when you are done using them (just as for a regular table).

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
       subtable = Tables.create("/tmp/my-sub-table.ms")
       subtable[kw"SECRET_CODE"] = Int32(42)
       table[kw"SUBTABLE"] = subtable
       Tables.close(subtable)
closed::CasaCore.Tables.TableStatus = 0

julia> subtable = table[kw"SUBTABLE"] # re-open the subtable
       subtable[kw"SECRET_CODE"]
42

julia> Tables.delete(table)
       Tables.delete(subtable)
```

## Best Practices

### Type Stability

Julia is a dynamically typed language. Because of this we can write statements like `column =
table["column"]` without knowing the type of the column ahead of time. If the column contains
`float`s (`Float32`), Julia will do the right thing. If the column contains `double`s (`Float64`),
Julia will do the right thing. As a user, we did not need to know whether this column contains
`float`s or `double`s ahead of time.

However Julia also performs "type-inference". This means that Julia will attempt to deduce the types
of your variables. If the types of your variables can be inferred at *compile time*, Julia will
generate more efficient machine code specialized on the types that it inferred. If the types of your
variables cannot be inferred at *compile time*, Julia will need to generate less efficient generic
code to account for the uncertainty in the types of your variables.

This concept is important for `CasaCore.Tables` because the result of `table["column"]` can be a
wide variety of different types, and the actual type isn't known until *run time*. Now consider the
following example:

```julia
function add_one_to_data_column(table)
    column = table["DATA"] # type of `column` cannot be inferred
    for idx in eachindex(column)
        column[idx] += 1
    end
    table["DATA"] = column
end
```

This function will read the `DATA` column from the given table, add one to each element, and then
write the result back to the table. However because the type of `column` cannot be inferred, the
performance of the `for`-loop will be sub-optimal. We can remedy this problem by moving the
computational kernel into a separate function:

```julia
function add_one_to_data_column(table)
    column = table["DATA"]
    do_the_for_loop(column) # `do_the_for_loop` specializes on the actual type of `column`
    table["DATA"] = column
end

function do_the_for_loop(column)
    for idx in eachindex(column)
        column[idx] += 1
    end
end
```

When `do_the_for_loop` is called, Julia will specialize the function on the actual type of `column`.
That is, the `for`-loop will be compiled with the knowledge of the actual type of `column`.  This
specialization ultimately means that the latter example will generally be faster.

For more information please refer to the [performance tips
section](https://docs.julialang.org/en/release-0.6/manual/performance-tips/#kernal-functions-1) of
the Julia manual.

