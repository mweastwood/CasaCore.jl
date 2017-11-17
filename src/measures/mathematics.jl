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

@noinline inconsistent_coordinate_system_error() = err("inconsistent coordinate system")
function check_coordinate_system(measure1, measure2)
    if measure1.sys != measure2.sys
        inconsistent_coordinate_system_error()
    end
end

function Base.:(==)(lhs::Directions.System, rhs::Positions.System)
    if lhs == Directions.ITRF && rhs == Positions.ITRF
        return true
    else
        return false
    end
end

function Base.:(==)(lhs::Directions.System, rhs::Baselines.System)
    Int32(lhs) == Int32(rhs)
end

function Base.:(==)(lhs::Positions.System, rhs::Baselines.System)
    if lhs == Positions.ITRF && rhs == Baselines.ITRF
        return true
    else
        return false
    end
end

Base.:(==)(lhs::Positions.System, rhs::Directions.System) = rhs == lhs
Base.:(==)(lhs::Baselines.System, rhs::Directions.System) = rhs == lhs
Base.:(==)(lhs::Baselines.System, rhs::Positions.System) = rhs == lhs

const ScalarMeasure = Union{Epoch}
const VectorMeasure = Union{Direction, Position, Baseline}

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
    lhs.sys === rhs.sys || err("Coordinate systems must match.")
    lhs.time ≈ rhs.time
end

function Base.isapprox(lhs::T, rhs::T) where T<:Union{Direction,Position,Baseline}
    lhs.sys === rhs.sys || err("Coordinate systems must match.")
    v1 = [lhs.x, lhs.y, lhs.z]
    v2 = [rhs.x, rhs.y, rhs.z]
    v1 ≈ v2
end

for op in (:+, :-)
    @eval function Base.$op(measure1::T, measure2::T) where T<:VectorMeasure
        check_coordinate_system(measure1, measure2)
        T(measure1.sys, $op(measure1.x, measure2.x),
                        $op(measure1.y, measure2.y),
                        $op(measure1.z, measure2.z))
    end
end

# Scalar multiplication is not defined for `Direction`, because `Direction` represents a normalized
# unit vector, so any multiplication would be immediately normalized away.
for op in (:*, :/)
    @eval function Base.$op(measure::T, scalar::Real) where T<:Union{Position, Baseline}
        T(measure.sys, $op(measure.x, scalar),
                       $op(measure.y, scalar),
                       $op(measure.z, scalar))
    end
    @eval function Base.$op(scalar::Real, measure::T) where T<:Union{Position, Baseline}
        T(measure.sys, $op(scalar, measure.x),
                       $op(scalar, measure.y),
                       $op(scalar, measure.z))
    end
end

function Base.dot(lhs::VectorMeasure, rhs::VectorMeasure)
    check_coordinate_system(lhs, rhs)
    (lhs.x*rhs.x + lhs.y*rhs.y + lhs.z*rhs.z) * units(lhs) * units(rhs)
end

function Base.cross(lhs::T, rhs::Direction) where T<:VectorMeasure
    do_cross_product(T, lhs, rhs)
end

function Base.cross(lhs::Direction, rhs::T) where T<:VectorMeasure
    do_cross_product(T, lhs, rhs)
end

function Base.cross(lhs::Direction, rhs::Direction)
    do_cross_product(Direction, lhs, rhs)
end

function do_cross_product(T, lhs, rhs)
    check_coordinate_system(lhs, rhs)
    T(lhs.sys, lhs.y*rhs.z - lhs.z*rhs.y,
               lhs.z*rhs.x - lhs.x*rhs.z,
               lhs.x*rhs.y - lhs.y*rhs.x)
end

function angle_between(lhs::Direction, rhs::Direction)
    acos(clamp(dot(lhs, rhs), -1, 1)) * u"rad"
end

function gram_schmidt(lhs::Direction, rhs::Direction)
    check_coordinate_system(lhs, rhs)
    d = dot(lhs, rhs)
    Direction(lhs.sys, lhs.x - d*rhs.x,
                       lhs.y - d*rhs.y,
                       lhs.z - d*rhs.z)
end

