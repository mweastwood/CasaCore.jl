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

template <typename T, typename R>
R* getKeyword_array(Table* t, char const* keyword) {
    Array<T> output;
    auto keywords = t->keywordSet();
    keywords.get(keyword, output);
    return output_array(output);
}

template <typename T, typename R>
void putKeyword_array(Table* t, char const* keyword, R* input, int const* dims, int ndim) {
    // Note that it is very important that `keywords` is a reference here. Otherwise we will make a
    // copy of the `TableRecord` and any changes will fail to propagate back to the table.
    TableRecord& keywords = t->rwKeywordSet();
    keywords.define(keyword, *input_array(input, dims, ndim));
}

//template <typename T>
//T getKeyword_column(Table* t, char const* column, char const* keyword) {
//    T output;
//    auto keywords = TableColumn(*t, column).keywordSet();
//    keywords.get(keyword, output);
//    return output;
//}
//
//template <typename T>
//void putKeyword_column(Table* t, char const* column, char const* keyword, T input) {
//    // Note that it is very important that `keywords` is a reference here. Otherwise we will make a
//    // copy of the `TableRecord` and any changes will fail to propagate back to the table.
//    TableRecord& keywords = TableColumn(*t, column).rwKeywordSet();
//    keywords.define(keyword, input);
//}

extern "C" {
    uint num_keywords(Table* t) {
        auto keywords = t->keywordSet();
        return keywords.nfields();
    }

    bool keyword_exists(Table* t, char* keyword) {
        auto keywords = t->keywordSet();
        return keywords.isDefined(keyword);
    }

    bool column_keyword_exists(Table* t, char* column, char* keyword) {
        auto keywords = TableColumn(*t, column).keywordSet();
        return keywords.isDefined(keyword);
    }

    void remove_keyword(Table* t, char* keyword) {
        TableRecord& keywords = t->rwKeywordSet();
        keywords.removeField(keyword);
    }

    void remove_column_keyword(Table* t, char* column, char* keyword) {
        TableRecord& keywords = TableColumn(*t, column).rwKeywordSet();
        keywords.removeField(keyword);
    }

    int* keyword_info(Table* t, char* keyword, int* element_type, int* dimension) {
        auto keywords = t->keywordSet();
        *element_type = keywords.dataType(keyword);
        auto iposition_shape = keywords.shape(keyword);
        *dimension = iposition_shape.size();
        int* shape = new int[*dimension];
        for (int i = 0; i < *dimension; ++i) {
            shape[i] = iposition_shape[i];
        }
        return shape;
    }

    //int getKeywordType_column(Table* t, char* column, char* keyword) {
    //    auto keywords = TableColumn(*t, column).keywordSet();
    //    return keywords.dataType(keyword);
    //}

    bool get_keyword_boolean(Table* t, char* keyword) {
        return getKeyword<Bool>(t, keyword);
    }
    int get_keyword_int(Table* t, char* keyword) {
        return getKeyword<Int>(t, keyword);
    }
    float get_keyword_float(Table* t, char* keyword) {
        return getKeyword<Float>(t, keyword);
    }
    double get_keyword_double(Table* t, char* keyword) {
        return getKeyword<Double>(t, keyword);
    }
    cmplx get_keyword_complex(Table* t, char* keyword) {
        return getKeyword<Complex>(t, keyword);
    }
    char* get_keyword_string(Table* t, char* keyword) {
        String string = getKeyword<String>(t, keyword);
        return output_string(string);
    }
    Table* get_keyword_table(Table* t, char* keyword) {
        auto keywords = t->keywordSet();
        return new Table(keywords.asTable(keyword));
    }

    void put_keyword_boolean(Table* t, char* keyword, bool input) {
        putKeyword<Bool>(t, keyword, input);
    }
    void put_keyword_int(Table* t, char* keyword, int input) {
        putKeyword<Int>(t, keyword, input);
    }
    void put_keyword_float(Table* t, char* keyword, float input) {
        putKeyword<Float>(t, keyword, input);
    }
    void put_keyword_double(Table* t, char* keyword, double input) {
        putKeyword<Double>(t, keyword, input);
    }
    void put_keyword_complex(Table* t, char* keyword, cmplx input) {
        putKeyword<Complex>(t, keyword, input);
    }
    void put_keyword_string(Table* t, char* keyword, char* input) {
        putKeyword<String>(t, keyword, input);
    }

    bool* get_keyword_array_boolean(Table* t, char* keyword) {
        return getKeyword_array<Bool, bool>(t, keyword);
    }
    int* get_keyword_array_int(Table* t, char* keyword) {
        return getKeyword_array<Int, int>(t, keyword);
    }
    float* get_keyword_array_float(Table* t, char* keyword) {
        return getKeyword_array<Float, float>(t, keyword);
    }
    double* get_keyword_array_double(Table* t, char* keyword) {
        return getKeyword_array<Double, double>(t, keyword);
    }
    cmplx* get_keyword_array_complex(Table* t, char* keyword) {
        return getKeyword_array<Complex, cmplx>(t, keyword);
    }
    char** get_keyword_array_string(Table* t, char* keyword) {
        return getKeyword_array<String, char*>(t, keyword);
    }

    void put_keyword_array_boolean(Table* t, char* keyword, bool* input, int* dims, int ndim) {
        putKeyword_array<Bool, bool>(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_int(Table* t, char* keyword, int* input, int* dims, int ndim) {
        putKeyword_array<Int, int>(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_float(Table* t, char* keyword, float* input, int* dims, int ndim) {
        putKeyword_array<Float, float>(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_double(Table* t, char* keyword, double* input, int* dims, int ndim) {
        putKeyword_array<Double, double>(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_complex(Table* t, char* keyword, cmplx* input, int* dims, int ndim) {
        putKeyword_array<Complex, cmplx>(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_string(Table* t, char* keyword, char** input, int* dims, int ndim) {
        putKeyword_array<String, char*>(t, keyword, input, dims, ndim);
    }

    //bool getKeyword_column_boolean(Table* t, char* column, char* keyword) {
    //    return getKeyword_column<Bool>(t, column, keyword);
    //}
    //int getKeyword_column_int(Table* t, char* column, char* keyword) {
    //    return getKeyword_column<Int>(t, column, keyword);
    //}
    //float getKeyword_column_float(Table* t, char* column, char* keyword) {
    //    return getKeyword_column<Float>(t, column, keyword);
    //}
    //double getKeyword_column_double(Table* t, char* column, char* keyword) {
    //    return getKeyword_column<Double>(t, column, keyword);
    //}
    //cmplx getKeyword_column_complex(Table* t, char* column, char* keyword) {
    //    return getKeyword_column<Complex>(t, column, keyword);
    //}
    //char* getKeyword_column_string(Table* t, char* column, char* keyword) {
    //    String string = getKeyword_column<String>(t, column, keyword);
    //    return output_string(string);
    //}

    //void putKeyword_column_boolean(Table* t, char* column, char* keyword, bool input) {
    //    return putKeyword_column<Bool>(t, column, keyword, input);
    //}
    //void putKeyword_column_int(Table* t, char* column, char* keyword, int input) {
    //    return putKeyword_column<Int>(t, column, keyword, input);
    //}
    //void putKeyword_column_float(Table* t, char* column, char* keyword, float input) {
    //    return putKeyword_column<Float>(t, column, keyword, input);
    //}
    //void putKeyword_column_double(Table* t, char* column, char* keyword, double input) {
    //    return putKeyword_column<Double>(t, column, keyword, input);
    //}
    //void putKeyword_column_complex(Table* t, char* column, char* keyword, cmplx input) {
    //    return putKeyword_column<Complex>(t, column, keyword, input);
    //}
    //void putKeyword_column_string(Table* t, char* column, char* keyword, char* input) {
    //    return putKeyword_column<String>(t, column, keyword, input);
    //}
}

