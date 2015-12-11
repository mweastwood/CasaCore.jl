# Tables

```julia
using CasaCore.Tables
```

Interacting with CasaCore tables requires you to first open the table:

```julia
table = Table("/path/to/table")
```

This will open an existing table or create a new table if a table does not already exist
at the given path. A lock will automatically be acquired on an open table. Release this
lock with `unlock(table)` and acquire it again with `lock(table)`.

**Measurement sets (for example from the [VLA](https://en.wikipedia.org/wiki/Karl_G._Jansky_Very_Large_Array))
are simply CasaCore tables with a standardized set of columns, keywords, and subtables.**
If you need to interface with a measurement set, `CasaCore.Tables` is right for you.

## Columns

Interfacing with columns in a table is straight-forward.

```julia
data = table["DATA"]
model_data = function_to_gen_model_visibilities()
table["MODEL_DATA"] = model_data
```

Note that in this example the `MODEL_DATA` column will be created in the table
if it does not already exist.

## Cells

If you do not want to read or write to an entire column, you can instead
pick a single row of the column (ie. a cell).

```julia
row = 1
cell = table["DATA", row]
table["MODEL_DATA", row] = new_cell
```

Note that the indexing order is column first, row second. This is opposite
from the usual matrix convention where the first index specifies the row.

Also note that the first row in a column is `1` (not `0`).

## Keywords

Keywords are accessed using the `kw"..."` string macro. For example:

```julia
ms_version = table[kw"MS_VERSION"]
table[kw"MS_VERSION"] = 2.0
```

## Subtables

Subtables can be opened by reading their location from the appropriate keyword,
and opening them as you would a regular table.

```julia
location = table[kw"SPECTRAL_WINDOW"]
subtable = Table(location)
```

