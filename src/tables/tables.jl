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

struct CasaCoreTable end

@enum TableStatus closed=0 readonly=1 readwrite=5

"""
    struct Table

This type is used to interact with CasaCore tables (including measurement sets).

**Fields:**

- `path` - the path to the table
- `status` - the current status of the table
- `ptr` - the pointer to the table object

**Constructors:**

**Usage:**

**See also:**
"""
struct Table
    path   :: String
    status :: Ref{TableStatus}
    ptr    :: Ptr{CasaCoreTable}
end

Base.unsafe_convert(::Type{Ptr{CasaCoreTable}}, table::Table) = table.ptr

function create(path)
    path = table_fix_path(path)
    if isfile(path) || isdir(path)
        table_exists_error()
    end
    ptr = ccall((:new_table_create, libcasacorewrapper), Ptr{CasaCoreTable},
                (Ptr{Cchar},), path)
    Table(path, readwrite, ptr)
end

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

function close(table::Table)
    if table.status[] != closed
        ccall((:delete_table, libcasacorewrapper), Void,
              (Ptr{CasaCoreTable},), table)
        table.status[] = closed
    end
end

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
    if table.status[] == closed
        str = " (closed)"
    elseif table.status[] == readonly
        str = " (read only)"
    elseif table.status[] == readwrite
        str = " (read/write)"
    else
        str = ""
    end
    print(io, "Table: ", table.path, str)
end

