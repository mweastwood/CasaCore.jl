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

extern "C" {
    uint num_columns(Table* t) {
        return t->tableDesc().ncolumn();
    }

    bool column_exists(Table* t, char* columnName) {
        return t->tableDesc().isColumn(columnName);
    }

    // add/remove columns

    void add_scalar_column_boolean(Table* t, char* name) {
        addScalarColumn<Bool>(t, name);
    }
    void add_scalar_column_int(Table* t, char* name) {
        addScalarColumn<Int>(t, name);
    }
    void add_scalar_column_float(Table* t, char* name) {
        addScalarColumn<Float>(t, name);
    }
    void add_scalar_column_double(Table* t, char* name) {
        addScalarColumn<Double>(t, name);
    }
    void add_scalar_column_complex(Table* t, char* name) {
        addScalarColumn<Complex>(t, name);
    }
    void add_scalar_column_string(Table* t, char* name) {
        addScalarColumn<String>(t, name);
    }

    void add_array_column_boolean(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Bool>(t, name, dim, ndim);
    }
    void add_array_column_int(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Int>(t, name, dim, ndim);
    }
    void add_array_column_float(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Float>(t, name, dim, ndim);
    }
    void add_array_column_double(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Double>(t, name, dim, ndim);
    }
    void add_array_column_complex(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<Complex>(t, name, dim, ndim);
    }
    void add_array_column_string(Table* t, char* name, int* dim, int ndim) {
        addArrayColumn<String>(t, name, dim, ndim);
    }

    void remove_column(Table* t, char* columnName) {
        t->removeColumn(columnName);
    }

    // get/put columns

    bool column_is_fixed_shape(Table* t, char* name) {
        ROTableColumn col(*t, name);
        return (col.columnDesc().options() & ColumnDesc::FixedShape) == ColumnDesc::FixedShape;
    }

    bool column_can_change_shape(Table* t, char* name) {
        // if a column is not fixed shape, it still might not be able to change shape :(
        ROTableColumn col(*t, name);
        return col.canChangeShape();
    }

    int* column_info(Table* t, char* name, int* element_type, int* dimension) {
        ROTableColumn col(*t, name);
        *element_type = col.columnDesc().dataType();
        if (col.columnDesc().isScalar()) {
            *dimension = 1;
            int* shape = new int[1];
            shape[0] = t->nrow();
            return shape;
        }
        else {
            if (column_is_fixed_shape(t, name)) {
                // for fixed shape columns we can use col.shapeColumn() to get the shape
                auto colshape = col.shapeColumn();
                *dimension = colshape.size() + 1;
                int* shape = new int[*dimension];
                for (uint i = 0; i < colshape.size(); ++i) {
                    shape[i] = colshape[i];
                }
                shape[*dimension - 1] = t->nrow();
                return shape;
            }
            else {
                // if the column doesn't have a fixed shape, we will rely on the shape of the array
                // in the first row to get the shape of the entire column, but we need to be sure
                // that the first row actually has an array in it (ie. it's not left undefined).
                if (col.isDefined(0)) {
                    *dimension = col.ndim(0) + 1;
                    int* shape = new int[*dimension];
                    auto colshape0 = col.shape(0);
                    for (uint i = 0; i < colshape0.size(); ++i) {
                        shape[i] = colshape0[i];
                    }
                    shape[*dimension - 1] = t->nrow();
                    return shape;
                }
                else {
                    *dimension = 1;
                    int* shape = new int[1];
                    shape[0] = t->nrow();
                    return shape;
                }
            }
        }
    }

    bool* get_column_boolean(Table* t, char* name) {
        return getColumn<Bool>(t, name);
    }
    int* get_column_int(Table* t, char* name) {
        return getColumn<Int>(t, name);
    }
    float* get_column_float(Table* t, char* name) {
        return getColumn<Float>(t, name);
    }
    double* get_column_double(Table* t, char* name) {
        return getColumn<Double>(t, name);
    }
    cmplx* get_column_complex(Table* t, char* name) {
        return getColumn<Complex>(t, name);
    }
    char** get_column_string(Table* t, char* name) {
        return getColumn<String, char*>(t, name);
    }

    void put_column_boolean(Table* t, char* name, bool* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void put_column_int(Table* t, char* name, int* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void put_column_float(Table* t, char* name, float* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void put_column_double(Table* t, char* name, double* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void put_column_complex(Table* t, char* name, cmplx* input, int* dims, int ndim) {
        putColumn(t, name, input, dims, ndim);
    }
    void put_column_string(Table* t, char* name, char** input, int* dims, int ndim) {
        putColumn<String, char*>(t, name, input, dims, ndim);
    }
}

