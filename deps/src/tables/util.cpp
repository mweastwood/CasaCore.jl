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

// Define a host of helpful methods that convert between casacore::Array and standard C arrays.
// Strings need to be special cased here.

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

extern "C" void free_string(char* string) {delete[] string;}

