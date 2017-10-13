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

template <typename T>
T getCell_scalar(Table* t, char const* name, uint row) {
    ScalarColumn<T> column(*t, name);
    return column(row);
}

template <typename T>
void putCell_scalar(Table* t, char const* name, uint row, T input) {
    ScalarColumn<T> column(*t, name);
    column.put(row, input);
}

template <typename T, typename R>
R* getCell_array(Table* t, char const* name, uint row) {
    ArrayColumn<T> column(*t, name);
    Array<T> array = column(row);
    return output_array(array);
}

template <typename T>
T* getCell_array(Table* t, char const* name, uint row) {
    return getCell_array<T, T>(t, name, row);
}

template <typename T, typename R>
void putCell_array(Table* t, char const* name, uint row, R* input, int const* dims, int ndim) {
    ArrayColumn<T> column(*t, name);
    auto array = input_array(input, dims, ndim);
    column.put(row, *array);
}

template <typename T>
void putCell_array(Table* t, char const* name, uint row, T* input, int const* dims, int ndim) {
    putCell_array<T, T>(t, name, row, input, dims, ndim);
}

template <typename T>
T getKeyword(Table* t, char const* keyword) {
    T output;
    auto keywords = t->keywordSet();
    keywords.get(keyword, output);
    return output;
}

template <typename T>
void putKeyword(Table* t, char const* keyword, T input) {
    // Note that it is very important that `keywords` is a reference here. Otherwise we will make a
    // copy of the `TableRecord` and any changes will fail to propagate back to the table.
    TableRecord& keywords = t->rwKeywordSet();
    keywords.define(keyword, input);
}

template <typename T>
T getKeyword_column(Table* t, char const* column, char const* keyword) {
    T output;
    auto keywords = TableColumn(*t, column).keywordSet();
    keywords.get(keyword, output);
    return output;
}

template <typename T>
void putKeyword_column(Table* t, char const* column, char const* keyword, T input) {
    // Note that it is very important that `keywords` is a reference here. Otherwise we will make a
    // copy of the `TableRecord` and any changes will fail to propagate back to the table.
    TableRecord& keywords = TableColumn(*t, column).rwKeywordSet();
    keywords.define(keyword, input);
}

// All the functions defined within `extern "C" { ... }` may be called directly from Julia.

extern "C" {
    // tables
    Table* new_table_open(char* path, int mode) {
        return new Table(path, Table::TableOption(mode));
    }
    Table* new_table_create(char* path) {
        SetupNewTable maker(path, TableDesc(), Table::NewNoReplace);
        return new Table(maker, 0); // 0 rows by default
    }
    void delete_table(Table* t) {delete t;}

    //bool lock(Table* t, bool write, int attempts) {return t->lock(write, attempts);}
    //void unlock(Table* t) {t->unlock();}

//
//    uint nkeyword(Table* t) {
//        auto keywords = t->keywordSet();
//        return keywords.nfields();
//    }
//    bool keywordExists(Table* t, char* keyword) {
//        auto keywords = t->keywordSet();
//        return keywords.isDefined(keyword);
//    }
//    bool keywordExists_column(Table* t, char* column, char* keyword) {
//        auto keywords = TableColumn(*t, column).keywordSet();
//        return keywords.isDefined(keyword);
//    }
//    void removeKeyword(Table* t, char* keyword) {
//        TableRecord& keywords = t->rwKeywordSet();
//        keywords.removeField(keyword);
//    }
//    void removeKeyword_column(Table* t, char* column, char* keyword) {
//        TableRecord& keywords = TableColumn(*t, column).rwKeywordSet();
//        keywords.removeField(keyword);
//    }
//
//    bool getCell_scalar_boolean(Table* t, char* name, uint row) {
//        return getCell_scalar<Bool>(t, name, row);
//    }
//    int getCell_scalar_int(Table* t, char* name, uint row) {
//        return getCell_scalar<Int>(t, name, row);
//    }
//    float getCell_scalar_float(Table* t, char* name, uint row) {
//        return getCell_scalar<Float>(t, name, row);
//    }
//    double getCell_scalar_double(Table* t, char* name, uint row) {
//        return getCell_scalar<Double>(t, name, row);
//    }
//    cmplx getCell_scalar_complex(Table* t, char* name, uint row) {
//        return getCell_scalar<Complex>(t, name, row);
//    }
//    char* getCell_scalar_string(Table* t, char* name, uint row) {
//        ScalarColumn<String> column(*t, name);
//        return output_string(column(row));
//    }
//
//    void putCell_scalar_boolean(Table* t, char* name, uint row, bool input) {
//        putCell_scalar(t, name, row, input);
//    }
//    void putCell_scalar_int(Table* t, char* name, uint row, int input) {
//        putCell_scalar(t, name, row, input);
//    }
//    void putCell_scalar_float(Table* t, char* name, uint row, float input) {
//        putCell_scalar(t, name, row, input);
//    }
//    void putCell_scalar_double(Table* t, char* name, uint row, double input) {
//        putCell_scalar(t, name, row, input);
//    }
//    void putCell_scalar_complex(Table* t, char* name, uint row, cmplx input) {
//        putCell_scalar(t, name, row, input);
//    }
//    void putCell_scalar_string(Table* t, char* name, uint row, char* input) {
//        putCell_scalar(t, name, row, String(input));
//    }
//
//    bool* getCell_array_boolean(Table* t, char* name, uint row) {
//        return getCell_array<Bool>(t, name, row);
//    }
//    int* getCell_array_int(Table* t, char* name, uint row) {
//        return getCell_array<Int>(t, name, row);
//    }
//    float* getCell_array_float(Table* t, char* name, uint row) {
//        return getCell_array<Float>(t, name, row);
//    }
//    double* getCell_array_double(Table* t, char* name, uint row) {
//        return getCell_array<Double>(t, name, row);
//    }
//    cmplx* getCell_array_complex(Table* t, char* name, uint row) {
//        return getCell_array<Complex>(t, name, row);
//    }
//    char** getCell_array_string(Table* t, char* name, uint row) {
//        return getCell_array<String, char*>(t, name, row);
//    }
//
//    void putCell_array_boolean(Table* t, char* name, uint row, bool* input, int* dims, int ndim) {
//        return putCell_array(t, name, row, input, dims, ndim);
//    }
//    void putCell_array_int(Table* t, char* name, uint row, int* input, int* dims, int ndim) {
//        return putCell_array(t, name, row, input, dims, ndim);
//    }
//    void putCell_array_float(Table* t, char* name, uint row, float* input, int* dims, int ndim) {
//        return putCell_array(t, name, row, input, dims, ndim);
//    }
//    void putCell_array_double(Table* t, char* name, uint row, double* input, int* dims, int ndim) {
//        return putCell_array(t, name, row, input, dims, ndim);
//    }
//    void putCell_array_complex(Table* t, char* name, uint row, cmplx* input, int* dims, int ndim) {
//        return putCell_array(t, name, row, input, dims, ndim);
//    }
//    void putCell_array_string(Table* t, char* name, uint row, char** input, int* dims, int ndim) {
//        return putCell_array<String, char*>(t, name, row, input, dims, ndim);
//    }
//
//    int getKeywordType(Table* t, char* keyword) {
//        auto keywords = t->keywordSet();
//        return keywords.dataType(keyword);
//    }
//
//    int getKeywordType_column(Table* t, char* column, char* keyword) {
//        auto keywords = TableColumn(*t, column).keywordSet();
//        return keywords.dataType(keyword);
//    }
//
//    bool getKeyword_boolean(Table* t, char* keyword) {
//        return getKeyword<Bool>(t, keyword);
//    }
//    int getKeyword_int(Table* t, char* keyword) {
//        return getKeyword<Int>(t, keyword);
//    }
//    float getKeyword_float(Table* t, char* keyword) {
//        return getKeyword<Float>(t, keyword);
//    }
//    double getKeyword_double(Table* t, char* keyword) {
//        return getKeyword<Double>(t, keyword);
//    }
//    cmplx getKeyword_complex(Table* t, char* keyword) {
//        return getKeyword<Complex>(t, keyword);
//    }
//    char* getKeyword_string(Table* t, char* keyword) {
//        String string = getKeyword<String>(t, keyword);
//        return output_string(string);
//    }
//
//    void putKeyword_boolean(Table* t, char* keyword, bool input) {
//        return putKeyword<Bool>(t, keyword, input);
//    }
//    void putKeyword_int(Table* t, char* keyword, int input) {
//        return putKeyword<Int>(t, keyword, input);
//    }
//    void putKeyword_float(Table* t, char* keyword, float input) {
//        return putKeyword<Float>(t, keyword, input);
//    }
//    void putKeyword_double(Table* t, char* keyword, double input) {
//        return putKeyword<Double>(t, keyword, input);
//    }
//    void putKeyword_complex(Table* t, char* keyword, cmplx input) {
//        return putKeyword<Complex>(t, keyword, input);
//    }
//    void putKeyword_string(Table* t, char* keyword, char* input) {
//        return putKeyword<String>(t, keyword, input);
//    }
//
//    bool getKeyword_column_boolean(Table* t, char* column, char* keyword) {
//        return getKeyword_column<Bool>(t, column, keyword);
//    }
//    int getKeyword_column_int(Table* t, char* column, char* keyword) {
//        return getKeyword_column<Int>(t, column, keyword);
//    }
//    float getKeyword_column_float(Table* t, char* column, char* keyword) {
//        return getKeyword_column<Float>(t, column, keyword);
//    }
//    double getKeyword_column_double(Table* t, char* column, char* keyword) {
//        return getKeyword_column<Double>(t, column, keyword);
//    }
//    cmplx getKeyword_column_complex(Table* t, char* column, char* keyword) {
//        return getKeyword_column<Complex>(t, column, keyword);
//    }
//    char* getKeyword_column_string(Table* t, char* column, char* keyword) {
//        String string = getKeyword_column<String>(t, column, keyword);
//        return output_string(string);
//    }
//
//    void putKeyword_column_boolean(Table* t, char* column, char* keyword, bool input) {
//        return putKeyword_column<Bool>(t, column, keyword, input);
//    }
//    void putKeyword_column_int(Table* t, char* column, char* keyword, int input) {
//        return putKeyword_column<Int>(t, column, keyword, input);
//    }
//    void putKeyword_column_float(Table* t, char* column, char* keyword, float input) {
//        return putKeyword_column<Float>(t, column, keyword, input);
//    }
//    void putKeyword_column_double(Table* t, char* column, char* keyword, double input) {
//        return putKeyword_column<Double>(t, column, keyword, input);
//    }
//    void putKeyword_column_complex(Table* t, char* column, char* keyword, cmplx input) {
//        return putKeyword_column<Complex>(t, column, keyword, input);
//    }
//    void putKeyword_column_string(Table* t, char* column, char* keyword, char* input) {
//        return putKeyword_column<String>(t, column, keyword, input);
//    }
}

