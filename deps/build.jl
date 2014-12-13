using BinDeps
@BinDeps.setup

# OpenBLAS
blas = library_dependency("libblas",aliases=["libopenblas"])
provides(AptGet,Dict("libopenblas-dev" => blas))

# CasaCore
casa_tables     = library_dependency("libcasa_tables")
casa_measures   = library_dependency("libcasa_measures")
casacore_libraries = [casa_tables,casa_measures]

version = "1.7.0"
url = "ftp://ftp.atnf.csiro.au/pub/software/casacore/casacore-$version.tar.bz2"
provides(Sources, URI(url), casacore_libraries, unpacked_dir="casacore-$version")

depsdir  = BinDeps.depsdir(casa_tables)
srcdir   = joinpath(depsdir,"src",   "casacore-$version")
builddir = joinpath(depsdir,"builds","casacore-$version")
prefix   = joinpath(depsdir,"usr")
files    = [joinpath(prefix,"lib",library.name*".so") for library in casacore_libraries]
provides(BuildProcess,
        (@build_steps begin
                GetSources(casa_tables)
                GetSources(casa_measures)
                CreateDirectory(builddir)
                @build_steps begin
                        ChangeDirectory(builddir)
                        FileRule(files,@build_steps begin
                                `cmake -DMODULE="tables" -DMODULE="measures" -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_CXX_FLAGS="-w" $srcdir`
                                `make -j2`
                                `make install`
                        end)
                end
        end),casacore_libraries)

# CasaCore Wrapper
casacorewrapper = library_dependency("libcasacorewrapper")

version = "1.7.0"
url = "ftp://ftp.atnf.csiro.au/pub/software/casacore/casacore-$version.tar.bz2"
provides(Sources, URI(url), casacorewrapper, unpacked_dir="casacore-$version")

depsdir  = BinDeps.depsdir(casacorewrapper)
builddir = joinpath(depsdir,"builds","casacorewrapper")
prefix   = joinpath(depsdir,"usr")
files    = [joinpath(prefix,"lib","libcasacorewrapper.so")]
provides(BuildProcess,
        (@build_steps begin
                GetSources(casacorewrapper)
                CreateDirectory(builddir)
                @build_steps begin
                        ChangeDirectory(builddir)
                        FileRule(files,@build_steps begin
                                `make`
                                `make install`
                                `ls -la ../../usr/lib`
                        end)
                end
        end),casacorewrapper)

@BinDeps.install

