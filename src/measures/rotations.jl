# Copyright (c) 2015-2017 Michael Eastwood
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

struct RotationMatrix{Sys}
    sys :: Sys
    matrix :: SArray{Tuple{3, 3}, Float64, 2, 9}
end

function RotationMatrix(from::AnyDirection, to::AnyDirection)
    check_coordinate_system(from, to)
    # https://math.stackexchange.com/a/476311
    a = Direction(from)
    b = Direction(to)
    v = cross(a, b)
    c =   dot(a, b) # cos(θ)
    V = @SMatrix [   0 -v.z  v.y;
                   v.z    0 -v.x;
                  -v.y  v.x    0]
    RotationMatrix(from.sys, I + V + V*V/(1+c))
end

function Base.:*(matrix::RotationMatrix, measure::T) where T<:VectorMeasure
    check_coordinate_system(matrix, measure)
    from = @SVector [measure.x, measure.y, measure.z]
    to = matrix.matrix * from
    T(measure.sys, to[1], to[2], to[3])
end

