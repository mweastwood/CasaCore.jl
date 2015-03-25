depsdir = dirname(@__FILE__)

# Download the CasaCore source
println("Downloading the CasaCore source...")
version = "1.7.0"
bz2 = "casacore-$version.tar.bz2"
url = "ftp://ftp.atnf.csiro.au/pub/software/casacore/$bz2"
dir = joinpath(depsdir,"downloads")

run(`mkdir -p $dir`)
run(`curl -o $(joinpath(dir,bz2)) -L $url`)
run(`tar -xjf $(joinpath(dir,bz2)) -C $dir`)

# Build the CasaCore wrapper
println("Building the CasaCore wrapper...")
dir = joinpath(depsdir,"src")
run(`make -C $dir`)
run(`make -C $dir install`)

