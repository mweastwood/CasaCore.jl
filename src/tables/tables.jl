# Copyright (c) 2015-2017 Michael Eastwood
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

@noinline table_exists_error() = err("Table already exists.")
@noinline table_does_not_exist_error() = err("Table does not exist.")
@noinline table_readonly_error() = err("Table is read-only.")
@noinline table_closed_error() = err("Table is closed.")

struct CasaCoreTable end

@enum TableStatus closed=0 readonly=1 readwrite=5

"""
    mutable struct Table

This type is used to interact with CasaCore tables (including measurement sets).

**Fields:**

- `path` - the path to the table
- `status` - the current status of the table
- `ptr` - the pointer to the table object

**Usage:**

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
Table: /tmp/my-table.ms (read/write)

julia> Tables.add_rows!(table, 3)
3

julia> table["DATA"] = Complex64[1+2im, 3+4im, 5+6im]
3-element Array{Complex{Float32},1}:
 1.0+2.0im
 3.0+4.0im
 5.0+6.0im

julia> Tables.close(table)
closed::CasaCore.Tables.TableStatus = 0

julia> table = Tables.open("/tmp/my-table.ms")
Table: /tmp/my-table.ms (read-only)

julia> table["DATA"]
3-element Array{Complex{Float32},1}:
 1.0+2.0im
 3.0+4.0im
 5.0+6.0im

julia> Tables.delete(table)
```

**See also:** [`Tables.create`](@ref), [`Tables.open`](@ref), [`Tables.close`](@ref),
[`Tables.delete`](@ref)
"""
mutable struct Table
    path   :: String
    status :: TableStatus
    ptr    :: Ptr{CasaCoreTable}
    function Table(path, status, ptr)
        table = new(path, status, ptr)
        finalizer(table, close)
        table
    end
end

enum2type[TpTable] = Table
Base.unsafe_convert(::Type{Ptr{CasaCoreTable}}, table::Table) = table.ptr

"""
    create(path)

Create a CasaCore table at the given path.

**Arguments:**

- `path` - the path where the table will be created

**Usage:**

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
Table: /tmp/my-table.ms (read/write)

julia> Tables.delete(table)
```

**See also:** [`Tables.open`](@ref), [`Tables.close`](@ref), [`Tables.delete`](@ref)
"""
function create(path)
    path = table_fix_path(path)
    if isfile(path) || isdir(path)
        table_exists_error()
    end
    ptr = ccall((:new_table_create, libcasacorewrapper), Ptr{CasaCoreTable},
                (Ptr{Cchar},), path)
    Table(path, readwrite, ptr)
end

"""
    open(path; write=false)

Open the CasaCore table at the given path.

**Arguments:**

- `path` - the path to the table that will be opened

**Keyword Arguments:**

- `write` - if `false` (the default) the table will be opened read-only

**Usage:**

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
Table: /tmp/my-table.ms (read/write)

julia> table′ = Tables.open("/tmp/my-table.ms")
Table: /tmp/my-table.ms (read-only)

julia> table″ = Tables.open("/tmp/my-table.ms", write=true)
Table: /tmp/my-table.ms (read/write)

julia> Tables.close(table′)
       Tables.close(table″)
       Tables.delete(table)
```

**See also:** [`Tables.create`](@ref), [`Tables.close`](@ref), [`Tables.delete`](@ref)
"""
function open(path; write=false)
    path = table_fix_path(path)
    if !isdir(path)
        table_does_not_exist_error()
    end
    mode = write ? readwrite : readonly
    ptr = ccall((:new_table_open, libcasacorewrapper), Ptr{CasaCoreTable},
                (Ptr{Cchar}, Cint), path, mode)
    Table(path, mode, ptr)
end

function open(table::Table; write=false)
    if !isopen(table)
        path = table_fix_path(table.path)
        if !isdir(path)
            table_does_not_exist_error()
        end
        mode = write ? readwrite : readonly
        ptr = ccall((:new_table_open, libcasacorewrapper), Ptr{CasaCoreTable},
                    (Ptr{Cchar}, Cint), path, mode)
        table.path   = path
        table.status = mode
        table.ptr    = ptr
    end
    table
end

"""
    close(table)

Close the given CasaCore table.

**Arguments:**

- `table` - the table to be closed

**Usage:**

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
Table: /tmp/my-table.ms (read/write)

julia> Tables.close(table)
closed::CasaCore.Tables.TableStatus = 0

julia> Tables.delete(table)
```

**See also:** [`Tables.create`](@ref), [`Tables.open`](@ref), [`Tables.delete`](@ref)
"""
function close(table::Table)
    if isopen(table)
        ccall((:delete_table, libcasacorewrapper), Void,
              (Ptr{CasaCoreTable},), table)
        table.status = closed
    end
end

"""
    delete(table)

Close and delete the given CasaCore table.

**Arguments:**

- `table` - the table to be deleted

**Usage:**

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
Table: /tmp/my-table.ms (read/write)

julia> Tables.delete(table)
```

**See also:** [`Tables.create`](@ref), [`Tables.open`](@ref), [`Tables.create`](@ref)
"""
function delete(table::Table)
    close(table)
    rm(table.path, recursive=true, force=true)
end

isopen(table::Table) = table.status != closed
iswritable(table::Table) = table.status == readwrite

function table_fix_path(path)
    # Remove the "Table: " prefix, if it exists
    if startswith(path, "Table: ")
        path = path[8:end]
    end
    # Expand a tilde to the home directory
    path = expanduser(path)
    # Normalize "." and ".."
    path = normpath(path)
end

function Base.show(io::IO, table::Table)
    if table.status == closed
        str = " (closed)"
    elseif table.status == readonly
        str = " (read-only)"
    elseif table.status == readwrite
        str = " (read/write)"
    end
    print(io, "Table: ", table.path, str)
end

