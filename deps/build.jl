depsdir = dirname(@__FILE__)

# Download the CasaCore source
println("Downloading the CasaCore source...")
version = "1.7.0"
bz2 = "casacore-$version.tar.bz2"
url = "ftp://ftp.atnf.csiro.au/pub/software/casacore/$bz2"

run(`mkdir -p downloads`)
run(`curl -o $(joinpath("downloads",bz2)) -L $url`)
run(`tar -xjf $(joinpath("downloads",bz2)) -C downloads`)

# Build the CasaCore wrapper
println("Building the CasaCore wrapper...")
run(`make -C src`)
run(`make -C src install`)

