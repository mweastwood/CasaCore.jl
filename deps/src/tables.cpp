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

#include <casa/Containers/ValueHolder.h>
#include <tables/Tables/TableProxy.h>
#include <tables/Tables/TableColumn.h>
#include <tables/Tables/ScaColData.h>
#include <tables/Tables/ArrColData.h>

#include "containers.h"

using namespace casa;
using std::complex;

extern "C" {
    TableProxy* newTable(char* name, char* endianFormat, char* memType, int nrow) {
        return new TableProxy(String(name),Record(),endianFormat,memType,nrow,Record(),Record());
    }
    TableProxy* newTable_existing(char* name, int option) {
        return new TableProxy(String(name),Record(),option);
    }
    void deleteTable(TableProxy* t) {delete t;}

    void flush(TableProxy* t, bool recursive) {t->flush(recursive);}

    bool isreadable(TableProxy const* t) {return t->isReadable();}
    bool iswritable(TableProxy const* t) {return t->isWritable();}

    int numrows(    TableProxy* t) {return t->nrows();}
    int numcolumns( TableProxy* t) {return t->ncolumns();}
    int numkeywords(TableProxy* t) {
        Record record = t->getKeywordSet(String());
        return record.nfields();
    }

    bool lock(TableProxy* t, bool write, int attempts) {
        return t->table().lock(write,attempts);
    }
    void unlock(TableProxy* t) {
        t->table().unlock();
    }
}

/******************************************************************************/
// Keyword Operations

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
int getKeywordLength(TableProxy* t, char* column, char* keyword) {
    ValueHolder value = t->getKeyword(column,keyword,-1);
    Array<T> arr;
    value.getValue(arr);
    return arr.size();
}

template <class T>
void getKeywordArray(TableProxy* t, char* column, char* keyword, T* output, size_t length) {
    ValueHolder value = t->getKeyword(column,keyword,-1);
    outputValueHolder<T>(value,output,length);
}

template <class T>
void putKeywordArray(TableProxy* t, char* column, char* keyword, T* input, size_t length) {
    ValueHolder value = createValueHolder(input,&length,1);
    t->putKeyword(column,keyword,-1,false,value);
}

extern "C" {
    int getKeywordType(TableProxy* t, char* column, char* keyword) {
        ValueHolder value = t->getKeyword(column,keyword,-1);
        return value.dataType();
    }

    bool   getKeyword_boolean(TableProxy* t, char* column, char* keyword) {return getKeyword<Bool>(t,column,keyword);}
    int    getKeyword_int(    TableProxy* t, char* column, char* keyword) {return getKeyword<Int>(t,column,keyword);}
    float  getKeyword_float(  TableProxy* t, char* column, char* keyword) {return getKeyword<Float>(t,column,keyword);}
    double getKeyword_double( TableProxy* t, char* column, char* keyword) {return getKeyword<Double>(t,column,keyword);}

    void putKeyword_boolean(TableProxy* t, char* column, char* keyword,   bool value) {return putKeyword<Bool>(t,column,keyword,value);}
    void putKeyword_int(    TableProxy* t, char* column, char* keyword,    int value) {return putKeyword<Int>(t,column,keyword,value);}
    void putKeyword_float(  TableProxy* t, char* column, char* keyword,  float value) {return putKeyword<Float>(t,column,keyword,value);}
    void putKeyword_double( TableProxy* t, char* column, char* keyword, double value) {return putKeyword<Double>(t,column,keyword,value);}

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

    int getKeywordLength_string(TableProxy* t, char* column, char* keyword) {
        return getKeywordLength<String>(t,column,keyword);
    }

    void getKeywordArray_string(TableProxy* t, char* column, char* keyword, char const** output, size_t length) {
        String arr[length];
        getKeywordArray(t,column,keyword,arr,length);
        for (uint i = 0; i < length; ++i) {
            output[i] = arr[i].c_str();
        }
    }

    void putKeywordArray_string(TableProxy* t, char* column, char* keyword, char** input, size_t length) {
        String arr[length];
        for (uint i = 0; i < length; ++i) {
            arr[i] = String(input[i]);
        }
        putKeywordArray<String>(t,column,keyword,arr,length);
    }
}

/******************************************************************************/
// Row Operations

extern "C" {
    void addRow(TableProxy* t, int nrows) {t->addRow(nrows);}
    bool canRemoveRow(TableProxy* t) {return t->table().canRemoveRow();}
    void removeRow(TableProxy* t, int* rownrs, size_t nrows) {
        Vector<Int> rows(Block<Int>(nrows,rownrs,false));
        t->removeRow(rows);
    }
}

/******************************************************************************/
// Column Operations

template <class T>
void addScalarColumn(TableProxy* t, char* name) {
    ScalarColumnDesc<T> column(name);
    t->table().addColumn(column);
}

template <class T>
void addArrayColumn(TableProxy* t, char* name, int* dim, size_t ndim) {
    IPosition dimensions(ndim);
    for (uint i = 0; i < ndim; ++i) {
        dimensions[i] = dim[i];
    }
    ArrayColumnDesc<T> column(name,"",dimensions);
    t->table().addColumn(column);
}

template <class T>
void getColumn(TableProxy* t, char* column, T* output, size_t length) {
    ValueHolder value = t->getColumn(column,0,-1,1);
    outputValueHolder<T>(value,output,length);
}

template <class T>
void putColumn(TableProxy* t, char* column, T* input, size_t* shape, size_t ndim) {
    ValueHolder value = createValueHolder(input,shape,ndim);
    t->putColumn(column,0,-1,1,value);
}

extern "C" {
    bool columnExists(TableProxy* t,char* name) {
        Vector<String> colnames = t->columnNames();
        for (int i = 0; i < numcolumns(t); ++i) {
            if (colnames[i].compare(name) == 0) return true;
        }
        return false;
    }

    void addScalarColumn_boolean(TableProxy* t, char* name) {addScalarColumn<Bool>(t,name);}
    void addScalarColumn_int(    TableProxy* t, char* name) {addScalarColumn<Int>(t,name);}
    void addScalarColumn_float(  TableProxy* t, char* name) {addScalarColumn<Float>(t,name);}
    void addScalarColumn_double( TableProxy* t, char* name) {addScalarColumn<Double>(t,name);}
    void addScalarColumn_complex(TableProxy* t, char* name) {addScalarColumn<Complex>(t,name);}

    void addArrayColumn_boolean(TableProxy* t, char* name, int* dim, size_t ndim) {addArrayColumn<Bool>(t,name,dim,ndim);}
    void addArrayColumn_int(    TableProxy* t, char* name, int* dim, size_t ndim) {addArrayColumn<Int>(t,name,dim,ndim);}
    void addArrayColumn_float(  TableProxy* t, char* name, int* dim, size_t ndim) {addArrayColumn<Float>(t,name,dim,ndim);}
    void addArrayColumn_double( TableProxy* t, char* name, int* dim, size_t ndim) {addArrayColumn<Double>(t,name,dim,ndim);}
    void addArrayColumn_complex(TableProxy* t, char* name, int* dim, size_t ndim) {addArrayColumn<Complex>(t,name,dim,ndim);}

    void removeColumn(TableProxy* t, char* name) {
        Vector<String> column(1);
        column[0] = String(name);
        t->removeColumns(column);
    }

    int getColumnType(TableProxy* t, char* column) {
        return t->table().tableDesc().columnDesc(column).dataType();
    }

    void getColumnShape(TableProxy* t, char* column, int* output, size_t outputlength) {
        if (t->isScalarColumn(String(column))) {
            if (outputlength > 1) {
                output[0] = numrows(t);
                output[1] = -1;
            }
        }
        else {
            // Possibly need to call syncTable(t) here.
            ROTableColumn col(t->table(),String(column));
            // Assume the number of dimensions and shape of the first cell
            // is representative of the entire column.
            uint ndim = col.ndim(0);
            IPosition shape = col.shape(0);
            for (uint i = 0; i < ndim && i < outputlength; ++i) {
                output[i] = shape[i];
            }
            if (outputlength > ndim+1) {
                output[ndim]   = numrows(t);
                output[ndim+1] = -1;
            }
        }
    }

    // Warning: there be long lines ahead

    void getColumn_boolean(TableProxy* t, char* column,           bool* output, size_t length) {getColumn<Bool>(t,column,output,length);}
    void getColumn_int(    TableProxy* t, char* column,            int* output, size_t length) {getColumn<Int>(t,column,output,length);}
    void getColumn_float(  TableProxy* t, char* column,          float* output, size_t length) {getColumn<Float>(t,column,output,length);}
    void getColumn_double( TableProxy* t, char* column,         double* output, size_t length) {getColumn<Double>(t,column,output,length);}
    void getColumn_complex(TableProxy* t, char* column, complex<float>* output, size_t length) {getColumn<Complex>(t,column,output,length);}

    void putColumn_boolean(TableProxy* t, char* column,           bool* input, size_t* shape, size_t ndim) {putColumn<Bool>(t,column,input,shape,ndim);}
    void putColumn_int(    TableProxy* t, char* column,            int* input, size_t* shape, size_t ndim) {putColumn<Int>(t,column,input,shape,ndim);}
    void putColumn_float(  TableProxy* t, char* column,          float* input, size_t* shape, size_t ndim) {putColumn<Float>(t,column,input,shape,ndim);}
    void putColumn_double( TableProxy* t, char* column,         double* input, size_t* shape, size_t ndim) {putColumn<Double>(t,column,input,shape,ndim);}
    void putColumn_complex(TableProxy* t, char* column, complex<float>* input, size_t* shape, size_t ndim) {putColumn<Complex>(t,column,input,shape,ndim);}
}

/******************************************************************************/
// Cell Operations

template <class T>
void getCell(TableProxy* t, char* column, int row, T* output, size_t length) {
    ValueHolder value = t->getCell(column,row);
    outputValueHolder<T>(value,output,length);
}

template <class T>
void putCell(TableProxy* t, char* column, int row, T* input, size_t* shape, size_t ndim) {
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
    void getCell_boolean(TableProxy* t, char* column, int row,           bool* output, size_t length) {getCell<Bool>(t,column,row,output,length);}
    void getCell_int(    TableProxy* t, char* column, int row,            int* output, size_t length) {getCell<Int>(t,column,row,output,length);}
    void getCell_float(  TableProxy* t, char* column, int row,          float* output, size_t length) {getCell<Float>(t,column,row,output,length);}
    void getCell_double( TableProxy* t, char* column, int row,         double* output, size_t length) {getCell<Double>(t,column,row,output,length);}
    void getCell_complex(TableProxy* t, char* column, int row, complex<float>* output, size_t length) {getCell<Complex>(t,column,row,output,length);}

    void putCell_boolean(TableProxy* t, char* column, int row,           bool* input, size_t* shape, size_t ndim) {putCell<Bool>(t,column,row,input,shape,ndim);}
    void putCell_int(    TableProxy* t, char* column, int row,            int* input, size_t* shape, size_t ndim) {putCell<Int>(t,column,row,input,shape,ndim);}
    void putCell_float(  TableProxy* t, char* column, int row,          float* input, size_t* shape, size_t ndim) {putCell<Float>(t,column,row,input,shape,ndim);}
    void putCell_double( TableProxy* t, char* column, int row,         double* input, size_t* shape, size_t ndim) {putCell<Double>(t,column,row,input,shape,ndim);}
    void putCell_complex(TableProxy* t, char* column, int row, complex<float>* input, size_t* shape, size_t ndim) {putCell<Complex>(t,column,row,input,shape,ndim);}

    void putCell_scalar_boolean(TableProxy* t, char* column, int row,           bool input) {putCell_scalar<Bool>(t,column,row,input);}
    void putCell_scalar_int(    TableProxy* t, char* column, int row,            int input) {putCell_scalar<Int>(t,column,row,input);}
    void putCell_scalar_float(  TableProxy* t, char* column, int row,          float input) {putCell_scalar<Float>(t,column,row,input);}
    void putCell_scalar_double( TableProxy* t, char* column, int row,         double input) {putCell_scalar<Double>(t,column,row,input);}
    void putCell_scalar_complex(TableProxy* t, char* column, int row, complex<float> input) {putCell_scalar<Complex>(t,column,row,input);}
}

