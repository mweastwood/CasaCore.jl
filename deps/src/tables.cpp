// Copyright (c) 2015 Michael Eastwood
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
#include <casa/Containers/ValueHolder.h>
#include <tables/Tables.h>
#include <tables/Tables/TableProxy.h>

using namespace std;
using namespace casa;

template <class T>
ValueHolder createValueHolder(T* input, int* shape, int ndim) {
    IPosition dimensions(ndim);
    for (int i = 0; i < ndim; ++i) {
        dimensions[i] = shape[i];
    }
    Array<T> arr(dimensions, input, SHARE);
    return ValueHolder(arr);
}

template <class T>
T outputValueHolder(ValueHolder& value) {
    T output;
    value.getValue(output);
    return output;
}

template <class T>
void outputValueHolder(ValueHolder& value, T* output, int length) {
    Array<T> arr;
    value.getValue(arr);
    T* data = arr.data();
    memcpy(output, data, length*sizeof(T));
}

// Table Operations

extern "C" {
    TableProxy* newTable() {return new TableProxy();}
    TableProxy* newTable_create(char* name) {
        return new TableProxy(name, Record(), "local", "plain", 0, Record(), Record());
    }
    TableProxy* newTable_existing(char* name) {
        return new TableProxy(name, Record(), Table::Update);
    }
    void deleteTable(TableProxy* t) {delete t;}

    bool isreadable(TableProxy const* t) {return t->isReadable();}
    bool iswritable(TableProxy const* t) {return t->isWritable();}

    bool lock(TableProxy* t, bool write, int attempts) {return t->table().lock(write,attempts);}
    void unlock(TableProxy* t) {t->table().unlock();}

    int numrows(    TableProxy* t) {return t->nrows();}
    int numcolumns( TableProxy* t) {return t->ncolumns();}
    int numkeywords(TableProxy* t) {
        Record keywords = t->getKeywordSet("");
        return keywords.nfields();
    }

    void addRow(TableProxy* t, int nrows) {t->addRow(nrows);}

    void removeColumn(TableProxy* t, char* name) {
        Vector<String> column(1);
        column[0] = String(name);
        t->removeColumns(column);
    }

    int name_length(TableProxy* t) {return t->tableName().length();}
    void name(TableProxy* t, char* output) {
        String str = t->tableName();
        int N = str.length();
        for (int i = 0; i < N; ++i) {
            output[i] = str[i];
        }
    }
}

// Read/Write Columns

extern "C" {
    bool columnExists(TableProxy* t, char* column) {
        Vector<String> colnames = t->columnNames();
        for (uint i = 0; i < colnames.size(); ++i) {
            if (colnames[i].compare(column) == 0) return true;
        }
        return false;
    }

    int getColumnType(TableProxy* t, char* column) {
        ROTableColumn col(t->table(), column);
        return col.columnDesc().dataType();
    }

    int getColumnDim(TableProxy* t, char* column) {
        ROTableColumn col(t->table(), column);
        if (col.columnDesc().isScalar()) {
            return 1;
        }
        else {
            return col.ndim(0) + 1;
        }
    }

    void getColumnShape(TableProxy* t, char* column, int* output) {
        ROTableColumn col(t->table(), column);
        if (col.columnDesc().isScalar()) {
            output[0] = numrows(t);
        }
        else {
            IPosition shape = col.shape(0);
            for (uint i = 0; i < shape.size(); ++i) {
                output[i] = shape[i];
            }
            output[shape.size()] = numrows(t);
        }
    }
}

template <class T>
void addScalarColumn(TableProxy* t, char* name) {
    ScalarColumnDesc<T> column(name);
    t->table().addColumn(column);
}

template <class T>
void addArrayColumn(TableProxy* t, char* name, int* dim, int ndim) {
    IPosition dimensions(ndim);
    for (int i = 0; i < ndim; ++i) {
        dimensions[i] = dim[i];
    }
    ArrayColumnDesc<T> column(name,"",dimensions);
    t->table().addColumn(column);
}

template <class T>
void getColumn(TableProxy* t, char* column, T* output, int length) {
    ValueHolder value = t->getColumn(column,0,-1,1);
    outputValueHolder<T>(value,output,length);
}

template <class T>
void putColumn(TableProxy* t, char* column, T* input, int* shape, int ndim) {
    ValueHolder value = createValueHolder(input,shape,ndim);
    t->putColumn(column,0,-1,1,value);
}

extern "C" {
    void addScalarColumn_boolean(TableProxy* t, char* name) {addScalarColumn<Bool>(t,name);}
    void addScalarColumn_int(    TableProxy* t, char* name) {addScalarColumn<Int>(t,name);}
    void addScalarColumn_float(  TableProxy* t, char* name) {addScalarColumn<Float>(t,name);}
    void addScalarColumn_double( TableProxy* t, char* name) {addScalarColumn<Double>(t,name);}
    void addScalarColumn_complex(TableProxy* t, char* name) {addScalarColumn<Complex>(t,name);}

    void addArrayColumn_boolean(TableProxy* t, char* name, int* dim, int ndim) {addArrayColumn<Bool>(t,name,dim,ndim);}
    void addArrayColumn_int(    TableProxy* t, char* name, int* dim, int ndim) {addArrayColumn<Int>(t,name,dim,ndim);}
    void addArrayColumn_float(  TableProxy* t, char* name, int* dim, int ndim) {addArrayColumn<Float>(t,name,dim,ndim);}
    void addArrayColumn_double( TableProxy* t, char* name, int* dim, int ndim) {addArrayColumn<Double>(t,name,dim,ndim);}
    void addArrayColumn_complex(TableProxy* t, char* name, int* dim, int ndim) {addArrayColumn<Complex>(t,name,dim,ndim);}

    void getColumn_boolean(TableProxy* t, char* column,           bool* output, int length) {getColumn<Bool>(t,column,output,length);}
    void getColumn_int(    TableProxy* t, char* column,            int* output, int length) {getColumn<Int>(t,column,output,length);}
    void getColumn_float(  TableProxy* t, char* column,          float* output, int length) {getColumn<Float>(t,column,output,length);}
    void getColumn_double( TableProxy* t, char* column,         double* output, int length) {getColumn<Double>(t,column,output,length);}
    void getColumn_complex(TableProxy* t, char* column, complex<float>* output, int length) {getColumn<Complex>(t,column,output,length);}

    void putColumn_boolean(TableProxy* t, char* column,           bool* input, int* shape, int ndim) {putColumn<Bool>(t,column,input,shape,ndim);}
    void putColumn_int(    TableProxy* t, char* column,            int* input, int* shape, int ndim) {putColumn<Int>(t,column,input,shape,ndim);}
    void putColumn_float(  TableProxy* t, char* column,          float* input, int* shape, int ndim) {putColumn<Float>(t,column,input,shape,ndim);}
    void putColumn_double( TableProxy* t, char* column,         double* input, int* shape, int ndim) {putColumn<Double>(t,column,input,shape,ndim);}
    void putColumn_complex(TableProxy* t, char* column, complex<float>* input, int* shape, int ndim) {putColumn<Complex>(t,column,input,shape,ndim);}
}

// Read/Write Cells

template <class T>
void getCell(TableProxy* t, char* column, int row, T* output, int length) {
    ValueHolder value = t->getCell(column,row);
    outputValueHolder<T>(value,output,length);
}

template <class T>
void putCell(TableProxy* t, char* column, int row, T* input, int* shape, int ndim) {
    ValueHolder value = createValueHolder(input,shape,ndim);
    Vector<Int> rows(1); rows[0] = row;
    t->putCell(column,rows,value);
}

template <class T>
void putCell_scalar(TableProxy* t, char* column, int row, T input) {
    ValueHolder value(input);
    Vector<Int> rows(1); rows[0] = row;
    t->putCell(column,rows,value);
}

extern "C" {
    void getCell_boolean(TableProxy* t, char* column, int row,           bool* output, int length) {getCell<Bool>(t,column,row,output,length);}
    void getCell_int(    TableProxy* t, char* column, int row,            int* output, int length) {getCell<Int>(t,column,row,output,length);}
    void getCell_float(  TableProxy* t, char* column, int row,          float* output, int length) {getCell<Float>(t,column,row,output,length);}
    void getCell_double( TableProxy* t, char* column, int row,         double* output, int length) {getCell<Double>(t,column,row,output,length);}
    void getCell_complex(TableProxy* t, char* column, int row, complex<float>* output, int length) {getCell<Complex>(t,column,row,output,length);}

    void putCell_boolean(TableProxy* t, char* column, int row,           bool* input, int* shape, int ndim) {putCell<Bool>(t,column,row,input,shape,ndim);}
    void putCell_int(    TableProxy* t, char* column, int row,            int* input, int* shape, int ndim) {putCell<Int>(t,column,row,input,shape,ndim);}
    void putCell_float(  TableProxy* t, char* column, int row,          float* input, int* shape, int ndim) {putCell<Float>(t,column,row,input,shape,ndim);}
    void putCell_double( TableProxy* t, char* column, int row,         double* input, int* shape, int ndim) {putCell<Double>(t,column,row,input,shape,ndim);}
    void putCell_complex(TableProxy* t, char* column, int row, complex<float>* input, int* shape, int ndim) {putCell<Complex>(t,column,row,input,shape,ndim);}

    void putCell_scalar_boolean(TableProxy* t, char* column, int row,           bool input) {putCell_scalar<Bool>(t,column,row,input);}
    void putCell_scalar_int(    TableProxy* t, char* column, int row,            int input) {putCell_scalar<Int>(t,column,row,input);}
    void putCell_scalar_float(  TableProxy* t, char* column, int row,          float input) {putCell_scalar<Float>(t,column,row,input);}
    void putCell_scalar_double( TableProxy* t, char* column, int row,         double input) {putCell_scalar<Double>(t,column,row,input);}
    void putCell_scalar_complex(TableProxy* t, char* column, int row, complex<float> input) {putCell_scalar<Complex>(t,column,row,input);}
}

// Read/Write Keywords

extern "C" {
    bool keywordExists(TableProxy* t, char* column, char* keyword) {
        Vector<String> keywords = t->getFieldNames(column, "", -1);
        for (uint i = 0; i < keywords.size(); ++i) {
            if (keywords[i].compare(keyword) == 0) return true;
        }
        return false;
    }

    int getKeywordType(TableProxy* t, char* column, char* keyword) {

        ValueHolder value = t->getKeyword(column, keyword, -1);
        return value.dataType();
    }
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

