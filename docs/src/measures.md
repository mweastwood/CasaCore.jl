# Measures

``` @meta
CurrentModule = CasaCore.Measures
```

Load this module by running

``` julia
using CasaCore.Measures
```

The `Measures` module is used to interface with the CasaCore measures system, which can be used to
perform coordinate system conversions. For example, UTC time can be converted to atomic time, or a
B1950 coordinates can be converted to J2000 coordinates.

At the moment there are 3 different kinds of measures available:

1. [Epochs](@ref) - representing an instance in time
2. [Directions](@ref) - representing a direction to an object on the sky
3. [Positions](@ref) - representing a location on the Earth

## Units

CasaCore.Measures depends on the [Unitful](https://github.com/ajkeller34/Unitful.jl) package in
order to specify the units associated with various quantities. The Unitful package should have
automatically been installed when you ran `Pkg.add("CasaCore")`. You can load the Unitful package by
running `using Unitful` and [documentation for Unitful is also
available](http://ajkeller34.github.io/Unitful.jl). Unitful is a particularly elegant package for
unit-checked computation because the unit checking occurs at compile-time. That is, there is no
run-time overhead associated with using Unitful.

Unitful offers two ways to attach units to a quantity:

``` julia
using Unitful: m
x = 10.0 * u"m" # using the u"..." string macro
y = 10.0 * m    # using the Unitful.m object (which we have imported into our namespace)
```

The first approach using the string macro is generally preferred because it avoids polluting the
namespace. Simply replace the `...` in `u"..."` with your desired units. For example we could obtain
units of meters per second by writing `u"m/s"` or radians per kilometer-squared by writing
`u"rad/km^2"`.

CasaCore.Measures, however, will only expect quantities with three different kinds of units: times,
lengths, and angles. These are summarized below.

|    Unit    | Expression |
|:----------:|:----------:|
|   Seconds  |   `u"s"`   |
|    Days    |   `u"dy"`  |
|   Meters   |   `u"m"`   |
| Kilometers |   `u"km"`  |
|   Degrees  |   `u"°"`   |
|   Radians  |  `u"rad"`  |

!!! note
    The ° character for degrees con be obtained at the Julia REPL by typing `\degree` and then
    pressing `<tab>`. The Julia plugins for Emacs and vim also provide this functionality.

## Epochs

An epoch measure is created using the `Epoch(sys, time)` constructor where `sys` specifies the
coordinate system and `time` specifies the Julian date.

``` @docs
Epoch(::Epochs.System, ::Unitful.Time)
```

## Directions

``` @docs
Direction(::Directions.System, ::Angle, ::Angle)
```

## Positions

``` @docs
Position(::Positions.System, ::Unitful.Length, ::Angle, ::Angle)
observatory
```

## Coordinate System Conversions

``` @docs
ReferenceFrame
measure
```

