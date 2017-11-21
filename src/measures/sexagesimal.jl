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

"""
    sexagesimal(string)

Parse angles given in sexagesimal format.

The regular expression used here understands how to match hours and degrees.

**Examples:**

``` julia
sexagesimal("12h34m56.7s")
sexagesimal("+12d34m56.7s")
```
"""
function sexagesimal(str::AbstractString)
    # Explanation of the regular expression:
    # (\+|-)?       Capture a + or - sign if it is provided
    # (\d*\.?\d+)   Capture a decimal number (required)
    # (d|h)         Capture the letter d or the letter h (required)
    # (?:(\d*\.?\d+)m(?:(\d*\.?\d+)s)?)?
    #               Capture the decimal number preceding the letter m
    #               and if that is found, look for and capture the
    #               decimal number preceding the letter s
    regex = r"(\+|-)?(\d*\.?\d+)(d|h)(?:(\d*\.?\d+)m(?:(\d*\.?\d+)s)?)?"
    m = match(regex,str)
    m === nothing && err("Unknown sexagesimal format.")

    sign = m.captures[1] == "-" ? -1 : +1
    degrees_or_hours = float(m.captures[2])
    isdegrees = m.captures[3] == "d"
    minutes = m.captures[4] === nothing ? 0.0 : float(m.captures[4])
    seconds = m.captures[5] === nothing ? 0.0 : float(m.captures[5])

    minutes += seconds/60
    degrees_or_hours += minutes/60
    degrees = isdegrees ? degrees_or_hours : 15degrees_or_hours
    sign*degrees |> deg2rad
end

"""
    sexagesimal(angle; hours = false, digits = 0)

Construct a sexagesimal string from the given angle.

* If `hours` is `true`, the constructed string will use hours instead of degrees.
* `digits` specifies the number of decimal points to use for seconds/arcseconds.
"""
function sexagesimal(angle::T; hours::Bool = false, digits::Int = 0) where T
    if T <: Angle
        radians = uconvert(u"rad", angle) |> ustrip
    else
        radians = angle
    end
    if hours
        s = +1
        radians = mod2pi(radians)
    else
        s = sign(radians)
        radians = abs(radians)
    end
    if hours
        value = radians * 12/π
        value = round(value*3600, digits) / 3600
        q1 = floor(Int, value)
        s1 = @sprintf("%dh", q1)
        s < 0 && (s1 = "-"*s1)
    else
        value = radians * 180/π
        value = round(value*3600, digits) / 3600
        q1 = floor(Int, value)
        s1 = @sprintf("%dd", q1)
        s > 0 && (s1 = "+"*s1)
        s < 0 && (s1 = "-"*s1)
    end
    value = (value - q1) * 60
    q2 = floor(Int, value)
    s2 = @sprintf("%02dm", q2)
    value = (value - q2) * 60
    q3 = round(value, digits)
    s3 = @sprintf("%016.13f", q3)
    # remove the extra decimal places, but be sure to remove the
    # decimal point if we are removing all of the decimal places
    if digits == 0
        s3 = s3[1:2] * "s"
    else
        s3 = s3[1:digits+3] * "s"
    end
    string(s1, s2, s3)
end

