# Measures

```julia
using CasaCore.Measures
```

## Epochs

An `Epoch` represents an instance in time.

```julia
epoch = Epoch(epoch"UTC", modified_julian_date, "d")
```

* The first argument

**Recognized Coordinate Systems:**
`LAST`, `LMST`, `GMST1`, `GAST`, `UT1`, `UT2`, `UTC`,
`TAI`, `TDT`, `TCG`, `TDB`, `TCB`

--------------------------------------------------

## Directions

A `Direction` represents a position on the sky.

```julia
direction = Direction(dir"J2000", "19h59m28.35663s", "+40d44m02.0970s")
```

* The first argument specifies the coordinate system.
* The second argument specifies the longitude.
* The third argument specifies the latitude.

Alternatively the location of a known solar system object (see the list below)
may be obtained by using:

```julia
direction = Direction(dir"JUPITER")
```

**Recognized Coordinate Systems:**
`J2000`, `JMEAN`, `JTRUE`, `APP`, `B1950`, `B1950_VLA`, `BMEAN`, `BTRUE`,
`GALACTIC`, `HADEC`, `AZEL`, `AZELSW`, `AZELGEO`, `AZELSWGEO`, `JNAT`,
`ECLIPTIC`, `MECLIPTIC`, `TECLIPTIC`, `SUPERGAL`, `ITRF`, `TOPO`, `ICRS`,
`MERCURY`, `VENUS`, `MARS`, `JUPITER`, `SATURN`, `URANUS`, `NEPTUNE`,
`PLUTO`, `SUN`, `MOON`

--------------------------------------------------

## Positions

A `Position` represents a location on the Earth.

Alternatively the position of a known observatory may be obtained by using:

```julia
position = observatory("VLA")
```

**Recognized Coordinate Systems:**
`ITRF`, `WGS84`

--------------------------------------------------

## Baselines

**Recognized Coordinate Systems:**
`J2000`, `JMEAN`, `JTRUE`, `APP`, `B1950`, `B1950_VLA`, `BMEAN`, `BTRUE`,
`GALACTIC`, `HADEC`, `AZEL`, `AZELSW`, `AZELGEO`, `AZELSWGEO`, `JNAT`,
`ECLIPTIC`, `MECLIPTIC`, `TECLIPTIC`, `SUPERGAL`, `ITRF`, `TOPO`, `ICRS`

--------------------------------------------------

## Coordinate System Conversions

Some coordinate conversions require information about the associated frame of reference.
For example, the conversion from a J2000 right ascension and declination to a local
azimuth and elevation requires information about the observer's time and location.

Here are a few examples attaching information to a frame of reference:

```julia
frame = ReferenceFrame()
position = observatory("VLA")
time = Epoch(epoch"UTC", 50237.29, "d"))
set!(frame, position)
set!(frame, time)
```

```julia
frame = ReferenceFrame()
set!(frame, observatory("ALMA"))
```

In general, the amount of information required depends on the specific coordinate system
conversion. Converting between B1950 and J2000, for example, requires no additional information
about your frame of reference.

Once you have established the correct frame of reference, the conversion is performed as follows:

```julia
azel_direction = measure(frame, j2000_direction, dir"AZEL")
```

```julia
itrf_position = measure(frame, wgs84_position, pos"ITRF")
```

