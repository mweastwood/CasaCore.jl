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

int* keyword_info(TableRecord const& keywords, char const* keyword,
                  int* element_type, int* dimension) {
    *element_type = keywords.dataType(keyword);
    auto iposition_shape = keywords.shape(keyword);
    *dimension = iposition_shape.size();
    int* shape = new int[*dimension];
    for (int i = 0; i < *dimension; ++i) {
        shape[i] = iposition_shape[i];
    }
    return shape;
}

// getKeyword

template <typename T>
T getKeyword(TableRecord const& keywords, char const* keyword) {
    T output;
    keywords.get(keyword, output);
    return output;
}

template <typename T>
T getKeyword(Table* t, char const* keyword) {
    auto keywords = t->keywordSet();
    return getKeyword<T>(keywords, keyword);
}

template <typename T>
T getKeyword(Table* t, char const* column, char const* keyword) {
    auto keywords = TableColumn(*t, column).keywordSet();
    return getKeyword<T>(keywords, keyword);
}

// putKeyword

template <typename T>
void putKeyword(TableRecord& keywords, char const* keyword, T input) {
    keywords.define(keyword, input);
}

template <typename T>
void putKeyword(Table* t, char const* keyword, T input) {
    // Note that it is very important that `keywords` is a reference here. Otherwise we will make a
    // copy of the `TableRecord` and any changes will fail to propagate back to the table.
    TableRecord& keywords = t->rwKeywordSet();
    putKeyword(keywords, keyword, input);
}

template <typename T>
void putKeyword(Table* t, char const* column, char const* keyword, T input) {
    // Note that it is very important that `keywords` is a reference here. Otherwise we will make a
    // copy of the `TableRecord` and any changes will fail to propagate back to the table.
    TableRecord& keywords = TableColumn(*t, column).rwKeywordSet();
    putKeyword(keywords, keyword, input);
}

// getKeyword_array

template <typename T, typename R>
R* getKeyword_array(TableRecord const& keywords, char const* keyword) {
    Array<T> output;
    keywords.get(keyword, output);
    return output_array(output);
}

template <typename T, typename R>
R* getKeyword_array(Table* t, char const* keyword) {
    auto keywords = t->keywordSet();
    return getKeyword_array<T, R>(keywords, keyword);
}

template <typename T, typename R>
R* getKeyword_array(Table* t, char const* column, char const* keyword) {
    auto keywords = TableColumn(*t, column).keywordSet();
    return getKeyword_array<T, R>(keywords, keyword);
}

// putKeyword_array

template <typename T>
void putKeyword_array(TableRecord& keywords, char const* keyword,
                      T* input, int const* dims, int ndim) {
    keywords.define(keyword, *input_array(input, dims, ndim));
}

template <typename T>
void putKeyword_array(Table* t, char const* keyword, T* input, int const* dims, int ndim) {
    // Note that it is very important that `keywords` is a reference here. Otherwise we will make a
    // copy of the `TableRecord` and any changes will fail to propagate back to the table.
    TableRecord& keywords = t->rwKeywordSet();
    putKeyword_array(keywords, keyword, input, dims, ndim);
}

template <typename T>
void putKeyword_array(Table* t, char const* column, char const* keyword,
                      T* input, int const* dims, int ndim) {
    // Note that it is very important that `keywords` is a reference here. Otherwise we will make a
    // copy of the `TableRecord` and any changes will fail to propagate back to the table.
    TableRecord& keywords = TableColumn(*t, column).rwKeywordSet();
    putKeyword_array(keywords, keyword, input, dims, ndim);
}

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
        return keyword_info(t->keywordSet(), keyword, element_type, dimension);
    }

    int* column_keyword_info(Table* t, char* column, char* keyword,
                             int* element_type, int* dimension) {
        return keyword_info(TableColumn(*t, column).keywordSet(), keyword,
                            element_type, dimension);
    }

    // Table Keywords

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
        Table* output = new Table(keywords.asTable(keyword));
        return output;
    }

    void put_keyword_boolean(Table* t, char* keyword, bool input) {
        putKeyword(t, keyword, input);
    }
    void put_keyword_int(Table* t, char* keyword, int input) {
        putKeyword(t, keyword, input);
    }
    void put_keyword_float(Table* t, char* keyword, float input) {
        putKeyword(t, keyword, input);
    }
    void put_keyword_double(Table* t, char* keyword, double input) {
        putKeyword(t, keyword, input);
    }
    void put_keyword_complex(Table* t, char* keyword, cmplx input) {
        putKeyword(t, keyword, input);
    }
    void put_keyword_string(Table* t, char* keyword, char* input) {
        putKeyword(t, keyword, input);
    }
    void put_keyword_table(Table* t, char* keyword, Table* input) {
        TableRecord& keywords = t->rwKeywordSet();
        keywords.defineTable(keyword, *input);
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
        putKeyword_array(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_int(Table* t, char* keyword, int* input, int* dims, int ndim) {
        putKeyword_array(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_float(Table* t, char* keyword, float* input, int* dims, int ndim) {
        putKeyword_array(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_double(Table* t, char* keyword, double* input, int* dims, int ndim) {
        putKeyword_array(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_complex(Table* t, char* keyword, cmplx* input, int* dims, int ndim) {
        putKeyword_array(t, keyword, input, dims, ndim);
    }
    void put_keyword_array_string(Table* t, char* keyword, char** input, int* dims, int ndim) {
        putKeyword_array(t, keyword, input, dims, ndim);
    }

    // Column Keywords

    bool get_column_keyword_boolean(Table* t, char* column, char* keyword) {
        return getKeyword<Bool>(t, column, keyword);
    }
    int get_column_keyword_int(Table* t, char* column, char* keyword) {
        return getKeyword<Int>(t, column, keyword);
    }
    float get_column_keyword_float(Table* t, char* column, char* keyword) {
        return getKeyword<Float>(t, column, keyword);
    }
    double get_column_keyword_double(Table* t, char* column, char* keyword) {
        return getKeyword<Double>(t, column, keyword);
    }
    cmplx get_column_keyword_complex(Table* t, char* column, char* keyword) {
        return getKeyword<Complex>(t, column, keyword);
    }
    char* get_column_keyword_string(Table* t, char* column, char* keyword) {
        String string = getKeyword<String>(t, column, keyword);
        return output_string(string);
    }

    void put_column_keyword_boolean(Table* t, char* column, char* keyword, bool input) {
        putKeyword<Bool>(t, column, keyword, input);
    }
    void put_column_keyword_int(Table* t, char* column, char* keyword, int input) {
        putKeyword<Int>(t, column, keyword, input);
    }
    void put_column_keyword_float(Table* t, char* column, char* keyword, float input) {
        putKeyword<Float>(t, column, keyword, input);
    }
    void put_column_keyword_double(Table* t, char* column, char* keyword, double input) {
        putKeyword<Double>(t, column, keyword, input);
    }
    void put_column_keyword_complex(Table* t, char* column, char* keyword, cmplx input) {
        putKeyword<Complex>(t, column, keyword, input);
    }
    void put_column_keyword_string(Table* t, char* column, char* keyword, char* input) {
        putKeyword<String>(t, column, keyword, input);
    }

    bool* get_column_keyword_array_boolean(Table* t, char* column, char* keyword) {
        return getKeyword_array<Bool, bool>(t, column, keyword);
    }
    int* get_column_keyword_array_int(Table* t, char* column, char* keyword) {
        return getKeyword_array<Int, int>(t, column, keyword);
    }
    float* get_column_keyword_array_float(Table* t, char* column, char* keyword) {
        return getKeyword_array<Float, float>(t, column, keyword);
    }
    double* get_column_keyword_array_double(Table* t, char* column, char* keyword) {
        return getKeyword_array<Double, double>(t, column, keyword);
    }
    cmplx* get_column_keyword_array_complex(Table* t, char* column, char* keyword) {
        return getKeyword_array<Complex, cmplx>(t, column, keyword);
    }
    char** get_column_keyword_array_string(Table* t, char* column, char* keyword) {
        return getKeyword_array<String, char*>(t, column, keyword);
    }

    void put_column_keyword_array_boolean(Table* t, char* column, char* keyword,
                                          bool* input, int* dims, int ndim) {
        putKeyword_array(t, column, keyword, input, dims, ndim);
    }
    void put_column_keyword_array_int(Table* t, char* column, char* keyword,
                                      int* input, int* dims, int ndim) {
        putKeyword_array(t, column, keyword, input, dims, ndim);
    }
    void put_column_keyword_array_float(Table* t, char* column, char* keyword,
                                        float* input, int* dims, int ndim) {
        putKeyword_array(t, column, keyword, input, dims, ndim);
    }
    void put_column_keyword_array_double(Table* t, char* column, char* keyword,
                                         double* input, int* dims, int ndim) {
        putKeyword_array(t, column, keyword, input, dims, ndim);
    }
    void put_column_keyword_array_complex(Table* t, char* column, char* keyword,
                                          cmplx* input, int* dims, int ndim) {
        putKeyword_array(t, column, keyword, input, dims, ndim);
    }
    void put_column_keyword_array_string(Table* t, char* column, char* keyword,
                                         char** input, int* dims, int ndim) {
        putKeyword_array(t, column, keyword, input, dims, ndim);
    }
}

