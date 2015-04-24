# Copyright (c) 2015 Michael Eastwood
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

function ra(hours,minutes=0.0,seconds=0.0)
    Quantity(15.*(hours+minutes/60.+seconds/3600.),Degree)
end

function dec(sign,degrees,minutes=0.0,seconds=0.0)
    Quantity(sign*(degrees+minutes/60.+seconds/3600.),Degree)
end

@doc """
Parse a string of the form 12h34m56.7s.
""" ->
function parse_ra(string::AbstractString)
    # Match eg. 12h34m56.7s
    regex = r"([0-9]?[0-9])h([0-9]?[0-9])m([0-9]?[0-9]\.?[0-9]*)s"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        return ra(float(substrs[1]),float(substrs[2]),float(substrs[3]))
    end
    # Match eg. 12h34.5m
    regex = r"([0-9]?[0-9])h([0-9]?[0-9]\.?[0-9]*)m"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        return ra(float(substrs[1]),float(substrs[2]))
    end
    # Match eg. 12.3h
    regex = r"([0-9]?[0-9]\.?[0-9]*)h"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        return ra(float(substrs[1]))
    end
    error("Unknown right ascension format: $string")
end

@doc """
Parse a string of the form +12d34m56.7s.
""" ->
function parse_dec(string::AbstractString)
    # Match eg. 12d34m56.7s
    regex = r"(\+|\-)?([0-9]?[0-9]?[0-9])d([0-9]?[0-9])m([0-9]?[0-9]\.?[0-9]*)s"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        sign = substrs[1] == "-"? -1 : +1
        return dec(sign,float(substrs[2]),float(substrs[3]),float(substrs[4]))
    end
    # Match eg. 12d34.5m
    regex = r"(\+|\-)?([0-9]?[0-9]?[0-9])d([0-9]?[0-9]\.?[0-9]*)m"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        sign = substrs[1] == "-"? -1 : +1
        return dec(sign,float(substrs[2]),float(substrs[3]))
    end
    # Match eg. 12.3d
    regex = r"(\+|\-)?([0-9]?[0-9]?[0-9]\.?[0-9]*)d"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        sign = substrs[1] == "-"? -1 : +1
        return dec(sign,float(substrs[2]))
    end
    error("Unknown declination format: $string")
end

function format_ra(ra::Float64)
    ra /= 15
    ra  = mod(ra,24)
    hrs = floor(Integer,ra)
    ra  = (ra-hrs)*60
    min = floor(Integer,ra)
    ra  = (ra-min)*60
    sec = ra
    @sprintf("%dh%02dm%05.2fs",hrs,min,sec)
end

function format_dec(dec::Float64)
    s = sign(dec)
    dec *= s
    dec = mod(dec,90)
    deg = floor(Integer,dec)
    dec = (dec-deg)*60
    min = floor(Integer,dec)
    dec = (dec-min)*60
    sec = dec
    @sprintf("%+dd%02dm%05.2fs",s*deg,min,sec)
end

macro ra_str(string)
    parse_ra(string)
end

macro dec_str(string)
    parse_dec(string)
end

