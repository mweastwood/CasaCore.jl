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

type Quantity
    value::Float64
    unit::ASCIIString
end

const recordvalue = RecordField(Float64,"value")
const recordunit  = RecordField(ASCIIString,"unit")
Quantity(record::Record) = Quantity(record[recordvalue],record[recordunit])

function Record(quantity::Quantity)
    description = RecordDesc()
    addfield!(description,recordvalue)
    addfield!(description,recordunit)

    record = Record(description)
    record[recordvalue] = quantity.value
    record[recordunit]  = quantity.unit
    record
end

==(q1::Quantity,q2::Quantity) = (q1.value == q2.value) && (q1.unit == q2.unit)

@doc """
This macro constructs a Quantity from a string.
    
# Examples
* q"1234.5s" → Quantity(1234.5,"s")
* q"1.23e4s" → Quantity(1.23e4,"s")
* q"1.23rad" → Quantity(1.23,"rad")
* q"12h00m00s" → Quantity(float(π),"rad")
* q"+180d00m00s" → Quantity(float(π),"rad")
""" ->
macro q_str(string)
    # Check for hour angle format
    regex = r"([0-9]?[0-9])h([0-9]?[0-9])m([0-9]?[0-9]\.?[0-9]*)s"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        return Quantity((float(substrs[1])+float(substrs[2])/60.+float(substrs[3])/3600.)*π/12.,"rad")
    end
    regex = r"([0-9]?[0-9])h([0-9]?[0-9]\.?[0-9]*)m"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        return Quantity((float(substrs[1])+float(substrs[2])/60.)*π/12.,"rad")
    end
    regex = r"([0-9]?[0-9]\.?[0-9]*)h"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        return Quantity(float(substrs[1])*π/12.,"rad")
    end
    # Check for degrees/arcminutes/arcseconds format
    regex = r"(\+|\-)?([0-9]?[0-9]?[0-9])d([0-9]?[0-9])m([0-9]?[0-9]\.?[0-9]*)s"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        sign = substrs[1] == "-"? -1 : +1
        return Quantity(sign*(float(substrs[2])+float(substrs[3])/60.+float(substrs[4])/3600.)*π/180.,"rad")
    end
    regex = r"(\+|\-)?([0-9]?[0-9]?[0-9])d([0-9]?[0-9]\.?[0-9]*)m"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        sign = substrs[1] == "-"? -1 : +1
        return Quantity(sign*(float(substrs[2])+float(substrs[3])/60.)*π/180.,"rad")
    end
    regex = r"(\+|\-)?([0-9]?[0-9]?[0-9]\.?[0-9]*)d"
    if match(regex,string) != nothing
        substrs = match(regex,string).captures
        sign = substrs[1] == "-"? -1 : +1
        return Quantity(sign*float(substrs[2])*π/180.,"rad")
    end
    # Check for generic unitful numbers
    regex   = r"((\+|\-)?[0-9]+\.?[0-9]*e?[0-9]*)([A-Za-z]+)"
    substrs = match(regex,string).captures
    Quantity(float(substrs[1]),ASCIIString(substrs[3]))
end

function show(io::IO,quantity::Quantity)
    print(io,"$(quantity.value) $(quantity.unit)")
end

