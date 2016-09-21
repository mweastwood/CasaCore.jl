# Copyright (c) 2015, 2016 Michael Eastwood
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

"""
Useful code that is shared between CasaCore submodules.
"""
module Common

export @wrap_pointer

macro wrap_pointer(name)
    cxx_delete = string("delete", name)
    cxx_new    = string("new", name)
    quote
        Base.@__doc__ type $name
            ptr :: Ptr{Void}
        end
        Base.unsafe_convert(::Type{Ptr{Void}}, x::$name) = x.ptr
        delete(x::$name) = ccall(($cxx_delete,libcasacorewrapper), Void, (Ptr{Void},), x)
        function $name()
            y = ccall(($cxx_new,libcasacorewrapper), Ptr{Void}, ()) |> $name
            finalizer(y, delete)
            y
        end
    end |> esc
end

end

