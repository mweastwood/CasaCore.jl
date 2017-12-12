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

const ScalarMeasure = Union{Epoch}
const VectorMeasure = Union{Direction, UnnormalizedDirection, Position, Baseline}
const AnyDirection  = Union{Direction, UnnormalizedDirection}

promote_vector_measure(::Type{Direction}) = UnnormalizedDirection
promote_vector_measure(::Type{T}) where {T<:VectorMeasure} = T
function promote_vector_measure(::Type{T}, ::Type{S}) where {T<:VectorMeasure, S<:VectorMeasure}
    Tp = promote_vector_measure(T)
    Sp = promote_vector_measure(S)
    if Tp == Sp
        return Tp
    else
        err("no common promotion")
    end
end

Base.norm(::Direction) = 1
function Base.norm(measure::T) where T<:VectorMeasure
    hypot(measure.x, measure.y, measure.z) * units(T)
end
function longitude(measure::VectorMeasure)
    atan2(measure.y, measure.x) * u"rad"
end
function latitude(measure::VectorMeasure)
    atan2(measure.z, hypot(measure.x, measure.y)) * u"rad"
end

function Base.isapprox(lhs::Epoch, rhs::Epoch)
    check_coordinate_system(lhs, rhs)
    lhs.time ≈ rhs.time
end

function Base.isapprox(lhs::T, rhs::T) where T<:VectorMeasure
    check_coordinate_system(lhs, rhs)
    v1 = [lhs.x, lhs.y, lhs.z]
    v2 = [rhs.x, rhs.y, rhs.z]
    v1 ≈ v2
end

for op in (:+, :-)
    @eval function Base.$op(measure1::T, measure2::S) where {T<:VectorMeasure, S<:VectorMeasure}
        check_coordinate_system(measure1, measure2)
        Tp = promote_vector_measure(T, S)
        Tp(measure1.sys, $op(measure1.x, measure2.x),
                         $op(measure1.y, measure2.y),
                         $op(measure1.z, measure2.z))
    end
end

for op in (:*, :/)
    @eval function Base.$op(measure::T, scalar::Real) where T<:VectorMeasure
        Tp = promote_vector_measure(T)
        Tp(measure.sys, $op(measure.x, scalar),
                        $op(measure.y, scalar),
                        $op(measure.z, scalar))
    end
    @eval function Base.$op(scalar::Real, measure::T) where T<:VectorMeasure
        Tp = promote_vector_measure(T)
        Tp(measure.sys, $op(scalar, measure.x),
                        $op(scalar, measure.y),
                        $op(scalar, measure.z))
    end
end

function Base.dot(lhs::VectorMeasure, rhs::VectorMeasure)
    check_coordinate_system(lhs, rhs)
    (lhs.x*rhs.x + lhs.y*rhs.y + lhs.z*rhs.z) * units(lhs) * units(rhs)
end

function Base.cross(lhs::T, rhs::AnyDirection) where T<:Union{Position, Baseline}
    do_cross_product(T, lhs.sys, lhs, rhs)
end
function Base.cross(lhs::AnyDirection, rhs::T) where T<:Union{Position, Baseline}
    do_cross_product(T, rhs.sys, lhs, rhs)
end
function Base.cross(lhs::T, rhs::S) where {T<:AnyDirection, S<:AnyDirection}
    Tp = promote_vector_measure(T, S)
    do_cross_product(Tp, lhs.sys, lhs, rhs)
end
function Base.cross(lhs::Direction, rhs::Direction)
    do_cross_product(Direction, lhs.sys, lhs, rhs)
end

function do_cross_product(T, sys, lhs, rhs)
    check_coordinate_system(lhs, rhs)
    T(sys, lhs.y*rhs.z - lhs.z*rhs.y,
           lhs.z*rhs.x - lhs.x*rhs.z,
           lhs.x*rhs.y - lhs.y*rhs.x)
end

function angle_between(lhs::AnyDirection, rhs::AnyDirection)
    check_coordinate_system(lhs, rhs)
    dotproduct = dot(Direction(lhs), Direction(rhs))
    acos(clamp(dotproduct, -1, 1)) * u"rad"
end

function gram_schmidt(lhs::AnyDirection, rhs::AnyDirection)
    check_coordinate_system(lhs, rhs)
    dotproduct = dot(Direction(lhs), Direction(rhs))
    Direction(lhs - dotproduct*rhs)
end

