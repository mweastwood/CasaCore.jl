// Copyright (c) 2015, 2016 Michael Eastwood
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

#include <iostream>
#include <memory>
#include <cstring>
#include <casacore/tables/Tables.h>

using namespace std;
using namespace casacore;

typedef complex<float> cmplx;

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

// First define a host of helpful methods that convert between casacore::Array and standard
// C arrays. Strings need to be special cased here.

IPosition create_shape(int length) {return IPosition(1, length);}
IPosition create_shape(int const* dims, int ndim) {
    IPosition output(ndim);
    for (int idx = 0; idx < ndim; ++idx) {
        output[idx] = dims[idx];
    }
    return output;
}

char* output_string(String const& string) {
    int N = string.length(); // length doesn't count null termination
    char* output = new char[N+1];
    strcpy(output, string.c_str());
    return output;
}

template <typename T>
T* output_array(Array<T> const& array) {
    auto shape = array.shape();
    int length = shape.product();
    T* output = new T[length];
    if (array.contiguousStorage()) {
        // If the array is contiguous we can use memcpy for maximum speed here.
        T const* raw = array.data();
        memcpy(output, raw, length*sizeof(T));
    }
    else {
        // This branch is relatively untested because I'm not entirely sure how to create a
        // non-contiguous array. The casacore documentation assures me that it can happen though.
        cout << "non-contiguous" << endl;
    }
    return output;
}

char** output_array(Array<String> const& array) {
    auto shape = array.shape();
    int length = shape.product();
    char** output = new char*[length];
    auto itr = array.begin();
    int idx = 0;
    while (itr != array.end()) {
        output[idx] = output_string(*itr);
        ++itr; ++idx;
    }
    return output;
}

template <typename T>
unique_ptr<Vector<T> > input_vector(T const* input, int length) {
    auto shape = create_shape(length);
    return unique_ptr<Vector<T> >(new Vector<T>(shape, input));
}

unique_ptr<Vector<String> > input_vector(char* const* input, int length) {
    auto vec = unique_ptr<Vector<String> >(new Vector<String>(length));
    auto itr = vec->begin();
    int idx = 0;
    while (itr != vec->end()) {
        *itr = String(input[idx]);
        ++itr; ++idx;
    }
    return vec;
}

template <typename T>
unique_ptr<Array<T> > input_array(T const* input, int const* dims, int ndim) {
    auto shape = create_shape(dims, ndim);
    return unique_ptr<Array<T> >(new Array<T>(shape, input));
}

unique_ptr<Array<String> > input_array(char* const* input, int const* dims, int ndim) {
    auto shape = create_shape(dims, ndim);
    auto arr = unique_ptr<Array<String> >(new Array<String>(shape));
    auto itr = arr->begin();
    int idx = 0;
    while (itr != arr->end()) {
        *itr = String(input[idx]);
        ++itr; ++idx;
    }
    return arr;
}

// Now define methods for interacting with casacore::Table. Again strings will usually need to be
// special cased.

template <typename T>
void addScalarColumn(Table* t, char const* name) {
    ScalarColumnDesc<T> column(name);
    t->addColumn(column);
}

template <typename T>
void addArrayColumn(Table* t, char const* name, int const* dims, int ndim) {
    auto shape = create_shape(dims, ndim);
    ArrayColumnDesc<T> column(name, shape);
    t->addColumn(column);
}

template <typename T, typename R>
R* getColumn(Table* t, char const* name) {
    auto table_description = t->tableDesc();
    auto column_description = table_description.columnDesc(name);
    if (column_description.isScalar()) {
        ScalarColumn<T> column(*t, name);
        Vector<T> values = column.getColumn();
        return output_array(values);
    }
    else {
        ArrayColumn<T> column(*t, name);
        Array<T> values = column.getColumn();
        return output_array(values);
    }
}

template <typename T>
T* getColumn(Table* t, char const* name) {
    return getColumn<T, T>(t, name);
}

template <typename T, typename R>
void putColumn(Table* t, char const* name, R const* input, int const* dims, int ndim) {
    auto table_description = t->tableDesc();
    auto column_description = table_description.columnDesc(name);
    if (column_description.isScalar()) {
        ScalarColumn<T> column(*t, name);
        auto vector = input_vector(input, dims[0]);
        column.putColumn(*vector);
    }
    else {
        ArrayColumn<T> column(*t, name);
        auto array = input_array(input, dims, ndim);
        column.putColumn(*array);
    }
}

template <typename T>
void putColumn(Table* t, char const* name, T const* input, int const* dims, int ndim) {
    putColumn<T, T>(t, name, input, dims, ndim);
}

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
    Table* newTable() {return new Table();}
    Table* newTable_create(char* name) {
        SetupNewTable maker(name, TableDesc(), Table::New);
        return new Table(maker, 0); // 0 rows by default
    }
    Table* newTable_update(char* name) {return new Table(name, Table::Update);}
    void deleteTable(Table* t) {delete t;}

    char* tableName(Table* t) {return output_string(t->tableName());}

    bool lock(Table* t, bool write, int attempts) {return t->lock(write, attempts);}
    void unlock(Table* t) {t->unlock();}

    uint nrow(Table* t) {return t->nrow();}
    void addRow(Table* t, uint nrrow) {t->addRow(nrrow, true);} // always initialize the new rows
    void removeRow(Table* t, uint* nrrow, size_t length) {
        auto my_nrrow = input_vector(nrrow, length);
        t->removeRow(*my_nrrow);
    }

    uint ncolumn(Table* t) {return t->tableDesc().ncolumn();}
    bool columnExists(Table* t, char* columnName) {return t->tableDesc().isColumn(columnName);}
    void removeColumn(Table* t, char* columnName) {t->removeColumn(columnName);}

    uint nkeyword(Table* t) {
        auto keywords = t->keywordSet();
        return keywords.nfields();
    }
    bool keywordExists(Table* t, char* keyword) {
        auto keywords = t->keywordSet();
        return keywords.isDefined(keyword);
    }
    bool keywordExists_column(Table* t, char* column, char* keyword) {
        auto keywords = TableColumn(*t, column).keywordSet();
        return keywords.isDefined(keyword);
    }
    void removeKeyword(Table* t, char* keyword) {
        TableRecord& keywords = t->rwKeywordSet();
        keywords.removeField(keyword);
    }
    void removeKeyword_column(Table* t, char* column, char* keyword) {
        TableRecord& keywords = TableColumn(*t, column).rwKeywordSet();
        keywords.removeField(keyword);
    }

    void addScalarColumn_boolean(Table* t, char* name) {addScalarColumn<Bool>(t, name);}
    void addScalarColumn_int(Table* t, char* name) {addScalarColumn<Int>(t, name);}
    void addScalarColumn_float(Table* t, char* name) {addScalarColumn<Float>(t, name);}
    void addScalarColumn_double(Table* t, char* name) {addScalarColumn<Double>(t, name);}
    void addScalarColumn_complex(Table* t, char* name) {addScalarColumn<Complex>(t, name);}
    void addScalarColumn_string(Table* t, char* name) {addScalarColumn<String>(t, name);}

    void addArrayColumn_boolean(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Bool>(t, name, dim, ndim);
    }
    void addArrayColumn_int(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Int>(t, name, dim, ndim);
    }
    void addArrayColumn_float(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Float>(t, name, dim, ndim);
    }
    void addArrayColumn_double(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Double>(t, name, dim, ndim);
    }
    void addArrayColumn_complex(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Complex>(t, name, dim, ndim);
    }
    void addArrayColumn_string(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<String>(t, name, dim, ndim);
    }

    int getColumnType(Table* t, char* name) {
        ROTableColumn col(*t, name);
        return col.columnDesc().dataType();
    }

    int getColumnDim(Table* t, char* name) {
        // TODO: make this function less ugly
        ROTableColumn col(*t, name);
        if (col.columnDesc().isScalar()) {
            return 1;
        }
        else {
            return col.ndim(0) + 1;
        }
    }

    int* getColumnShape(Table* t, char* name) {
        // TODO: make this function less ugly
        ROTableColumn col(*t, name);
        if (col.columnDesc().isScalar()) {
            int* output = new int[1];
            output[0] = nrow(t);
            return output;
        }
        else {
            auto shape = col.shape(0);
            int* output = new int[shape.size()+1];
            for (uint i = 0; i < shape.size(); ++i) {
                output[i] = shape[i];
            }
            output[shape.size()] = nrow(t);
            return output;
        }
    }

    bool* getColumn_boolean(Table* t, char* name) {
        return getColumn<Bool>(t, name);
    }
    int* getColumn_int(Table* t, char* name) {
        return getColumn<Int>(t, name);
    }
    float* getColumn_float(Table* t, char* name) {
        return getColumn<Float>(t, name);
    }
    double* getColumn_double(Table* t, char* name) {
        return getColumn<Double>(t, name);
    }
    cmplx* getColumn_complex(Table* t, char* name) {
        return getColumn<Complex>(t, name);
    }
    char** getColumn_string(Table* t, char* name) {
        return getColumn<String, char*>(t, name);
    }

    void putColumn_boolean(Table* t, char* name, bool* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void putColumn_int(Table* t, char* name, int* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void putColumn_float(Table* t, char* name, float* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void putColumn_double(Table* t, char* name, double* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void putColumn_complex(Table* t, char* name, cmplx* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void putColumn_string(Table* t, char* name, char** input, int* dims, int ndim) {
        putColumn<String, char*>(t, name, input, dims, ndim);
    }

    bool getCell_scalar_boolean(Table* t, char* name, uint row) {
        return getCell_scalar<Bool>(t, name, row);
    }
    int getCell_scalar_int(Table* t, char* name, uint row) {
        return getCell_scalar<Int>(t, name, row);
    }
    float getCell_scalar_float(Table* t, char* name, uint row) {
        return getCell_scalar<Float>(t, name, row);
    }
    double getCell_scalar_double(Table* t, char* name, uint row) {
        return getCell_scalar<Double>(t, name, row);
    }
    cmplx getCell_scalar_complex(Table* t, char* name, uint row) {
        return getCell_scalar<Complex>(t, name, row);
    }
    char* getCell_scalar_string(Table* t, char* name, uint row) {
        ScalarColumn<String> column(*t, name);
        return output_string(column(row));
    }

    void putCell_scalar_boolean(Table* t, char* name, uint row, bool input) {
        putCell_scalar(t, name, row, input);
    }
    void putCell_scalar_int(Table* t, char* name, uint row, int input) {
        putCell_scalar(t, name, row, input);
    }
    void putCell_scalar_float(Table* t, char* name, uint row, float input) {
        putCell_scalar(t, name, row, input);
    }
    void putCell_scalar_double(Table* t, char* name, uint row, double input) {
        putCell_scalar(t, name, row, input);
    }
    void putCell_scalar_complex(Table* t, char* name, uint row, cmplx input) {
        putCell_scalar(t, name, row, input);
    }
    void putCell_scalar_string(Table* t, char* name, uint row, char* input) {
        putCell_scalar(t, name, row, String(input));
    }

    bool* getCell_array_boolean(Table* t, char* name, uint row) {
        return getCell_array<Bool>(t, name, row);
    }
    int* getCell_array_int(Table* t, char* name, uint row) {
        return getCell_array<Int>(t, name, row);
    }
    float* getCell_array_float(Table* t, char* name, uint row) {
        return getCell_array<Float>(t, name, row);
    }
    double* getCell_array_double(Table* t, char* name, uint row) {
        return getCell_array<Double>(t, name, row);
    }
    cmplx* getCell_array_complex(Table* t, char* name, uint row) {
        return getCell_array<Complex>(t, name, row);
    }
    char** getCell_array_string(Table* t, char* name, uint row) {
        return getCell_array<String, char*>(t, name, row);
    }

    void putCell_array_boolean(Table* t, char* name, uint row, bool* input, int* dims, int ndim) {
        return putCell_array(t, name, row, input, dims, ndim);
    }
    void putCell_array_int(Table* t, char* name, uint row, int* input, int* dims, int ndim) {
        return putCell_array(t, name, row, input, dims, ndim);
    }
    void putCell_array_float(Table* t, char* name, uint row, float* input, int* dims, int ndim) {
        return putCell_array(t, name, row, input, dims, ndim);
    }
    void putCell_array_double(Table* t, char* name, uint row, double* input, int* dims, int ndim) {
        return putCell_array(t, name, row, input, dims, ndim);
    }
    void putCell_array_complex(Table* t, char* name, uint row, cmplx* input, int* dims, int ndim) {
        return putCell_array(t, name, row, input, dims, ndim);
    }
    void putCell_array_string(Table* t, char* name, uint row, char** input, int* dims, int ndim) {
        return putCell_array<String, char*>(t, name, row, input, dims, ndim);
    }

    int getKeywordType(Table* t, char* keyword) {
        auto keywords = t->keywordSet();
        return keywords.dataType(keyword);
    }

    int getKeywordType_column(Table* t, char* column, char* keyword) {
        auto keywords = TableColumn(*t, column).keywordSet();
        return keywords.dataType(keyword);
    }

    bool getKeyword_boolean(Table* t, char* keyword) {
        return getKeyword<Bool>(t, keyword);
    }
    int getKeyword_int(Table* t, char* keyword) {
        return getKeyword<Int>(t, keyword);
    }
    float getKeyword_float(Table* t, char* keyword) {
        return getKeyword<Float>(t, keyword);
    }
    double getKeyword_double(Table* t, char* keyword) {
        return getKeyword<Double>(t, keyword);
    }
    cmplx getKeyword_complex(Table* t, char* keyword) {
        return getKeyword<Complex>(t, keyword);
    }

    void putKeyword_boolean(Table* t, char* keyword, bool input) {
        return putKeyword<Bool>(t, keyword, input);
    }
    void putKeyword_int(Table* t, char* keyword, int input) {
        return putKeyword<Int>(t, keyword, input);
    }
    void putKeyword_float(Table* t, char* keyword, float input) {
        return putKeyword<Float>(t, keyword, input);
    }
    void putKeyword_double(Table* t, char* keyword, double input) {
        return putKeyword<Double>(t, keyword, input);
    }
    void putKeyword_complex(Table* t, char* keyword, cmplx input) {
        return putKeyword<Complex>(t, keyword, input);
    }

    bool getKeyword_column_boolean(Table* t, char* column, char* keyword) {
        return getKeyword_column<Bool>(t, column, keyword);
    }
    int getKeyword_column_int(Table* t, char* column, char* keyword) {
        return getKeyword_column<Int>(t, column, keyword);
    }
    float getKeyword_column_float(Table* t, char* column, char* keyword) {
        return getKeyword_column<Float>(t, column, keyword);
    }
    double getKeyword_column_double(Table* t, char* column, char* keyword) {
        return getKeyword_column<Double>(t, column, keyword);
    }
    cmplx getKeyword_column_complex(Table* t, char* column, char* keyword) {
        return getKeyword_column<Complex>(t, column, keyword);
    }

    void putKeyword_column_boolean(Table* t, char* column, char* keyword, bool input) {
        return putKeyword_column<Bool>(t, column, keyword, input);
    }
    void putKeyword_column_int(Table* t, char* column, char* keyword, int input) {
        return putKeyword_column<Int>(t, column, keyword, input);
    }
    void putKeyword_column_float(Table* t, char* column, char* keyword, float input) {
        return putKeyword_column<Float>(t, column, keyword, input);
    }
    void putKeyword_column_double(Table* t, char* column, char* keyword, double input) {
        return putKeyword_column<Double>(t, column, keyword, input);
    }
    void putKeyword_column_complex(Table* t, char* column, char* keyword, cmplx input) {
        return putKeyword_column<Complex>(t, column, keyword, input);
    }
}

/*

// Read/Write Cells

extern "C" {
}

template <class T>
int getKeywordLength(TableProxy* t, char* column, char* keyword) {
    ValueHolder value = t->getKeyword(column,keyword,-1);
    Array<T> arr;
    value.getValue(arr);
    return arr.size();
}

template <class T>
T getKeyword(TableProxy* t, char* column, char* keyword) {
    ValueHolder value = t->getKeyword(column,keyword,-1);
    return outputValueHolder<T>(value);
}

template <class T>
void putKeyword(TableProxy* t, char* column, char* keyword, T const& keywordvalue) {
    ValueHolder value(keywordvalue);
    t->putKeyword(column,keyword,-1,false,value);
}


template <class T>
void getKeywordArray(TableProxy* t, char* column, char* keyword, T* output, int length) {
    ValueHolder value = t->getKeyword(column,keyword,-1);
    outputValueHolder<T>(value,output,length);
}

template <class T>
void putKeywordArray(TableProxy* t, char* column, char* keyword, T* input, int length) {
    ValueHolder value = createValueHolder(input,&length,1);
    t->putKeyword(column,keyword,-1,false,value);
}

extern "C" {

    bool           getKeyword_boolean( TableProxy* t, char* column, char* keyword) {return getKeyword<Bool>(t,column,keyword);}
    int            getKeyword_int(     TableProxy* t, char* column, char* keyword) {return getKeyword<Int>(t,column,keyword);}
    float          getKeyword_float(   TableProxy* t, char* column, char* keyword) {return getKeyword<Float>(t,column,keyword);}
    double         getKeyword_double(  TableProxy* t, char* column, char* keyword) {return getKeyword<Double>(t,column,keyword);}
    complex<float> getKeyword_complex( TableProxy* t, char* column, char* keyword) {return getKeyword<Complex>(t,column,keyword);}

    void putKeyword_boolean( TableProxy* t, char* column, char* keyword,           bool value) {return putKeyword<Bool>(t,column,keyword,value);}
    void putKeyword_int(     TableProxy* t, char* column, char* keyword,            int value) {return putKeyword<Int>(t,column,keyword,value);}
    void putKeyword_float(   TableProxy* t, char* column, char* keyword,          float value) {return putKeyword<Float>(t,column,keyword,value);}
    void putKeyword_double(  TableProxy* t, char* column, char* keyword,         double value) {return putKeyword<Double>(t,column,keyword,value);}
    void putKeyword_complex( TableProxy* t, char* column, char* keyword, complex<float> value) {return putKeyword<Complex>(t,column,keyword,value);}

    int getKeyword_string_length(TableProxy* t, char* column, char* keyword) {
        return getKeyword<String>(t,column,keyword).length();
    }

    void getKeyword_string(TableProxy* t, char* column, char* keyword, char* output) {
        String str = getKeyword<String>(t,column,keyword);
        int N = str.length();
        for (int i = 0; i < N; ++i) {
            output[i] = str[i];
        }
    }

    void putKeyword_string(TableProxy* t, char* column, char* keyword, char* keywordvalue) {
        putKeyword<String>(t,column,keyword,keywordvalue);
    }
}
*/

