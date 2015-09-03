depsdir = dirname(@__FILE__)
src = joinpath(depsdir,"src")

# Download the CasaCore source
println("Downloading the CasaCore source...")
run(`git clone --branch v2.0.3 https://github.com/casacore/casacore`)

# Build the CasaCore wrapper
println("Building the CasaCore wrapper...")
run(`make -C $src`)
run(`make -C $src install`)

