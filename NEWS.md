# News

## v0.2.1

*unreleased*

* Arithmetic on `Direction` produces an `UnnormalizedDirection`, which can be converted back to a
  regular normalized `Direction`. This allows intermediate operations to be unnormalized before
  explicitly normalizing at the last step.
* Experimental (unexported) support for rotation matrices.

## v0.2.0

*2017-11-21*

* Package reorganization for compatibilitiy with Julia v0.6.
* Documentation improvements.
* Array keywords are now allowed.
* Subtable keywords are functional again.
* Some arithmetic operations on measures are now defined.

