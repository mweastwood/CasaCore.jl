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

function create(path)
    path = Tables.table_fix_path(path)
    if isfile(path) || isdir(path)
        Tables.table_exists_error()
    end
    ptr = ccall((:new_measurement_set_create, libcasacorewrapper), Ptr{Tables.CasaCoreTable},
                (Ptr{Cchar},), path)
    Table(path, Tables.readwrite, ptr)
end

