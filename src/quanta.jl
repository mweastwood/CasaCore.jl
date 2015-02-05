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

# Any automatic conversion between SIUnits and a string will be inherently brittle.
# This is because even if SIUnits commits to an interface (which it hasn't), we
# need that interface to match CasaCore. Doing the conversion manually gives us
# the most protection from any future changes to SIUnits or CasaCore.
#
# For the record, the conversion from ASCIIString to SIQuantity can currently be
# accomplished with eval(symbol(::ASCIIString)).
const si2str = Dict{SIUnits.SIUnit,ASCIIString}()
const str2si = Dict{ASCIIString,SIUnits.SIUnit}()
for (si,str) in ((Meter,"m"),(Second,"s"),(Radian,"rad"))
    si2str[si] = str
    str2si[str] = si
end

@doc """
This function takes a number value and a string unit, converting them to the
appropriate SIQuantity.
""" ->
function siquantity(value::Float64,unit::ASCIIString)
    value*str2si[unit]
end

function siquantity(record::Record)
    siquantity(record["value"],record["unit"])
end

function Record(quantity::SIUnits.SIQuantity)
    description = RecordDesc()
    addField!(description,"value",Float64)
    addField!(description,"unit",ASCIIString)

    record = Record(description)
    record["value"] = float(quantity)
    record["unit"]  = si2str[SIUnits.unit(quantity)]
    record
end

function ra(hours,minutes=0.0,seconds=0.0)
    (hours+minutes/60.+seconds/3600.) * π/12. * Radian
end

function ra_str{T<:Number}(number::quantity(T,Radian))
    number *= 12/(π*Radian)
    number += (number < 0)? 24 : 0
    hrs    = floor(Integer,number)
    number = (number-hrs)*60
    min    = floor(Integer,number)
    number = (number-min)*60
    sec    = number
    @sprintf("%dh%02dm%05.2fs",hrs,min,sec)
end

function ra_str(string::AbstractString)
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

macro ra_str(string)
    ra_str(string)
end

function dec(sign,degrees,minutes=0.0,seconds=0.0)
    sign * (degrees+minutes/60.+seconds/3600.) * π/180. * Radian
end

function dec_str{T<:Number}(number::quantity(T,Radian))
    s = sign(number.val)
    number *= 180/(π*Radian) * s
    deg    = floor(Integer,number)
    number = (number-deg)*60
    min    = floor(Integer,number)
    number = (number-min)*60
    sec    = number
    @sprintf("%+dd%02dm%05.2fs",s*deg,min,sec)
end

function dec_str(string::AbstractString)
    # Match eg. 23d34m56.7s
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

macro dec_str(string)
    dec_str(string)
end

