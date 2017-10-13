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

@noinline row_out_of_bounds_error(index) = err("The given row index is out of bounds: $index")

"""
    Tables.num_rows(table)

Returns the number of rows in the given table.

**Arguments:**

**Usage:**

**See also:**
"""
function num_rows(table::Table)
    ccall((:num_rows, libcasacorewrapper), Cuint,
          (Ptr{CasaCoreTable},), table) |> Int
end

"""
    Tables.add_rows!(table, number)

Add the given number of rows to the table.

**Arguments:**

**Usage:**

**See also:**
"""
function add_rows!(table::Table, number::Integer)
    ccall((:add_rows, libcasacorewrapper), Void,
          (Ptr{CasaCoreTable}, Cuint), table, number)
    number
end

"""
    Tables.remove_rows!(table, rows)

Remove the specified rows from the table.

**Arguments:**

**Usage:**

**See also:**
"""
function remove_rows!(table::Table, rows)
    N = num_rows(table)
    if any(rows .≤ 0) || any(rows .≥ N+1)
        row_out_of_bounds_error(rows)
    end
    c_rows = collect(rows.-1)
    ccall((:remove_rows, libcasacorewrapper), Void,
          (Ptr{CasaCoreTable}, Ptr{Cuint}, Csize_t),
          table, c_rows, length(c_rows))
    rows
end

