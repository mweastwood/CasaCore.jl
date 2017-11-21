// Copyright (c) 2015-2017 Michael Eastwood
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include "util.h"

// Tables can store data in a variety of places:
//
// * columns and rows
// * keywords associated with the table
// * keywords associated with a column
//
// All columns must have the same number of rows but they may either store scalars or arrays in
// each row. We need functions to read and write to both types of columns as well as writing to one
// cell (a single row of a single column) at a time.
//
// Similarly we must support reading and writing to keywords associated with the table and with
// each of the individual columns. We may store either scalars or arrays as keywords.
//
// Finally we must support a host of data types: bool, int, float, double, complex<float>, and
// strings among others. C does not support function overloading so we will need a separate method
// for each of these data types. Strings are special little snow flakes and will require some extra
// attention.
//
// As you can see a huge number of methods are required. We will make liberal use of C++ templating
// to make each of these method definitions as simple as possible. On the Julia side we will need
// to make use of meta-programming and multiple-dispatch to ease the pain of defining all the
// corresponding functions and then selecting which one to call.
//
// Note that I tried to keep this file as organized as possible, but there are simply so many
// definitions that it has inevitably become scattered. Apologies!

// Now define methods for interacting with casacore::Table. Again strings will usually need to be
// special cased.

// All the functions defined within `extern "C" { ... }` may be called directly from Julia.

extern "C" {
    Table* new_table_open(char* path, int mode) {
        return new Table(path, Table::TableOption(mode));
    }
    Table* new_table_create(char* path) {
        SetupNewTable maker(path, TableDesc(), Table::NewNoReplace);
        return new Table(maker, 0); // 0 rows by default
    }
    void delete_table(Table* t) {delete t;}

    char* table_name(Table* t) {
        return output_string(t->tableName());
    }
}

