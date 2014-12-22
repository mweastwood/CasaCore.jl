#include <casa/Containers/ValueHolder.h>
#include <tables/Tables/TableProxy.h>
#include <tables/Tables/TableColumn.h>
#include <tables/Tables/ScaColData.h>
#include <tables/Tables/ArrColData.h>

using namespace casa;

template <class T>
void getColumn(TableProxy* t, char* column, T* output, size_t length) {
    ValueHolder value = t->getColumn(String(column),0,-1,1);
    Array<T> arr(IPosition(1,length));
    value.getValue(arr);
    int idx = 0;
    for (typename Array<T>::IteratorSTL it = arr.begin(); it != arr.end(); ++it) {
        output[idx] = *it;
        ++idx;
    }
}

template <class T>
void putColumn(TableProxy* t, char* column, T* input, size_t* shape, size_t ndim) {
    IPosition dimensions(ndim);
    for (uint i = 0; i < ndim; ++i)
        dimensions[i] = shape[i];
    Array<T> arr(dimensions);
    int idx = 0;
    for (typename Array<T>::IteratorSTL it = arr.begin(); it != arr.end(); ++it) {
        *it = input[idx];
        ++idx;
    }
    ValueHolder value(arr);
    t->putColumn(String(column),0,-1,1,value);
}

template <class T>
T getKeyword(TableProxy* t, char* keyword) {
    ValueHolder value = t->getKeyword(String(),keyword,-1);
    T output;
    value.getValue(output);
    return output;
}

template <class T>
void putKeyword(TableProxy* t, char* keyword, T const& keywordvalue) {
    ValueHolder value(keywordvalue);
    t->putKeyword("",keyword,-1,false,value);
}

extern "C" {
    TableProxy* newTable(char* name, char* endianFormat, char* memType, int nrow) {
        return new TableProxy(String(name),Record(),endianFormat,memType,nrow,Record(),Record());
    }
    TableProxy* newTable_existing(char* name, int option) {
        return new TableProxy(String(name),Record(),option);
    }
    void deleteTable(TableProxy* t) {delete t;}

    void flush(TableProxy* t, bool recursive) {t->flush(recursive);}

    bool isReadable(TableProxy const* t) {return t->isReadable();}
    bool isWritable(TableProxy const* t) {return t->isWritable();}

    int nrows(TableProxy* t) {return t->nrows();}
    int ncolumns(TableProxy* t) {return t->ncolumns();}

    void addRow(TableProxy* t, int nrows) {t->addRow(nrows);}

    bool canRemoveRow(TableProxy* t) {return t->table().canRemoveRow();}
    void removeRow(TableProxy* t, int* rownrs, size_t nrows) {
        Vector<Int> rows(Block<Int>(nrows,rownrs,false));
        t->removeRow(rows);
    }

    void addScalarColumn(TableProxy* t, char* name, int type) {
        switch(type) {
        case TpInt:
            ScalarColumnDesc<Int> column(name);
            t->table().addColumn(column);
            break;
        }
    }

    void addArrayColumn(TableProxy* t, char* name, int type, int* dim, size_t ndim) {
        IPosition dimensions(ndim);
        for (uint i = 0; i < ndim; ++i) {
            dimensions[i] = dim[i];
        }
        if (type == TpInt) {
            ArrayColumnDesc<Int> column(name,"",dimensions);
            t->table().addColumn(column);
        }
        else if (type == TpFloat) {
            ArrayColumnDesc<Float> column(name,"",dimensions);
            t->table().addColumn(column);
        }
        else if (type == TpDouble) {
            ArrayColumnDesc<Double> column(name,"",dimensions);
            t->table().addColumn(column);
        }
        else if (type == TpComplex) {
            ArrayColumnDesc<Complex> column(name,"",dimensions);
            t->table().addColumn(column);
        }
    }

    void removeColumn(TableProxy* t, char* name) {
        Vector<String> column(1);
        column[0] = String(name);
        t->removeColumns(column);
    }

    unsigned int nKeywords(TableProxy* t) {
        Record record = t->getKeywordSet(String());
        return record.nfields();
    }

    char const* getKeyword_string(TableProxy* t, char* keyword) {
        return getKeyword<String>(t,keyword).c_str();
    }

    void putKeyword_string(TableProxy* t, char* keyword, char* keywordvalue) {
        putKeyword<String>(t,keyword,keywordvalue);
    }

    char const* getColumnType(TableProxy* t, char* column) {
        return t->columnDataType(column).c_str();
    }

    void getColumnShape(TableProxy* t, char* column, int* output, size_t outputlength) {
        if (t->isScalarColumn(String(column))) {
            if (outputlength > 1) {
                output[0] = nrows(t);
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
                output[ndim]   = nrows(t);
                output[ndim+1] = -1;
            }
        }
    }

    void getColumn_int(TableProxy* t, char* column,
                       int* output, size_t length) {
        getColumn<Int>(t,column,output,length);
    }

    void getColumn_float(TableProxy* t, char* column,
                         float* output, size_t length) {
        getColumn<Float>(t,column,output,length);
    }

    void getColumn_double(TableProxy* t, char* column,
                          double* output, size_t length) {
        getColumn<Double>(t,column,output,length);
    }

    void getColumn_complex(TableProxy* t, char* column,
                           std::complex<float>* output,
                           size_t length) {
        getColumn<Complex>(t,column,output,length);
    }

    void putColumn_int(TableProxy* t, char* column,
                       int* input, size_t* shape, size_t ndim) {
        putColumn<Int>(t,column,input,shape,ndim);
    }

    void putColumn_float(TableProxy* t, char* column,
                         float* input, size_t* shape, size_t ndim) {
        putColumn<Float>(t,column,input,shape,ndim);
    }
    
    void putColumn_double(TableProxy* t, char* column,
                          double* input, size_t* shape, size_t ndim) {
        putColumn<Double>(t,column,input,shape,ndim);
    }
    
    void putColumn_complex(TableProxy* t, char* column,
                           std::complex<float>* input,
                           size_t* shape, size_t ndim) {
        putColumn<Complex>(t,column,input,shape,ndim);
    }
}

