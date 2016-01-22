depsdir = dirname(@__FILE__)
src = joinpath(depsdir,"src")

# Build the CasaCore wrapper
println("Building the CasaCore wrapper...")
run(`make -C $src`)
run(`make -C $src install`)

