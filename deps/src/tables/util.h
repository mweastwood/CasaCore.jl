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

#ifndef JL_CASACORE_TABLES_UTIL_H
#define JL_CASACORE_TABLES_UTIL_H

#include <iostream>
#include <memory>
#include <cstring>
using namespace std;

#include <casacore/tables/Tables.h>
using namespace casacore;

typedef complex<float> cmplx;

// Define a host of helpful methods that convert between casacore::Array and standard C arrays.
// Strings need to be special cased here.
//
// NOTE: Templated functions need to be defined here. Regular functions should be defined in
// util.cpp.

IPosition create_shape(int length);
IPosition create_shape(int const* dims, int ndim);

char* output_string(String const& string);

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

char** output_array(Array<String> const& array);

template <typename T>
unique_ptr<Vector<T> > input_vector(T const* input, int length) {
    auto shape = create_shape(length);
    return unique_ptr<Vector<T> >(new Vector<T>(shape, input));
}

unique_ptr<Vector<String> > input_vector(char* const* input, int length);

template <typename T>
unique_ptr<Array<T> > input_array(T const* input, int const* dims, int ndim) {
    auto shape = create_shape(dims, ndim);
    return unique_ptr<Array<T> >(new Array<T>(shape, input));
}

unique_ptr<Array<String> > input_array(char* const* input, int const* dims, int ndim);

extern "C" void free_string(char* string);

#endif // JL_CASACORE_TABLES_UTIL_H

