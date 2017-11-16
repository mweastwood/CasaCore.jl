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

module Epochs
    @enum(System, LAST, LMST, GMST1, GAST, UT1, UT2, UTC, TAI, TDT, TCG, TDB, TCB)
    const IAT = TAI
    const GMST = GMST1
    const TT = TDT
    const UT = UT1
    const ET = TT
end

macro epoch_str(sys)
    eval(current_module(),:(Measures.Epochs.$(Symbol(sys))))
end

"""
    Epoch <: Measure

This type represents an instance in time.
"""
struct Epoch <: Measure
    sys  :: Epochs.System
    time :: Float64 # measured in seconds
end

units(::Type{Epoch}) = u"s"

"""
    Epoch(sys, time)

Instantiate an epoch in the given coordinate system (`sys`).

The `time` should be given as a modified Julian date.  Additionally the Unitful package should be
used to communicate the units of `time`.

For example `time = 57365.5 * u"d"` corresponds to a Julian date of 57365.5 days. However you can
also specify the Julian date in seconds (`u"s"`), or any other unit of time supported by Unitful.

**Coordinate Systems:**

The coordinate system is selected using the string macro `epoch"..."` where the `...` is replaced
with one of the coordinate systems listed below.

* `LAST` - local apparent sidereal time
* `LMST` - local mean sidereal time
* `GMST1` - Greenwich mean sidereal time
* `GAST` - Greenwich apparent sidereal time
* `UT1` - UT0 (raw time from GPS measurements) corrected for polar wandering
* `UT2` - UT1 corrected for variable Earth rotation
* `UTC` - coordinated universal time
* `TAI` - international atomic time
* `TDT` - terrestrial dynamical time
* `TCG` - geocentric coordinate time
* `TDB` - barycentric dynamical time
* `TCB` - barycentric coordinate time

**Examples:**

``` julia
using Unitful: d
Epoch(epoch"UTC",     0.0d) # 1858-11-17T00:00:00
Epoch(epoch"UTC", 57365.5d) # 2015-12-09T12:00:00
```
"""
function Epoch(sys::Epochs.System, time::Unitful.Time)
    seconds = uconvert(u"s", time) |> ustrip
    Epoch(sys, seconds)
end

function Base.show(io::IO, epoch::Epoch)
    julian_date = 2400000.5 + epoch.time/(24*60*60)
    print(io, Dates.julian2datetime(julian_date))
end

