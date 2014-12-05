using BinDeps
@BinDeps.setup

version = "1.7.0"
url = "ftp://ftp.atnf.csiro.au/pub/software/casacore/casacore-$version.tar.bz2"

libcasa_tables     = library_dependency("libcasa_tables")
libcasa_measures   = library_dependency("libcasa_measures")
libcasacorewrapper = library_dependency("libcasacorewrapper")
casacore_libraries = [libcasa_tables,libcasa_measures]
all_libraries = [casacore_libraries, libcasacorewrapper]

depsdir  = BinDeps.depsdir(libcasacorewrapper)
prefix   = joinpath(depsdir,"usr")

provides(Sources, URI(url), all_libraries, unpacked_dir="casacore-$version")

srcdir   = joinpath(depsdir,"src",   "casacore-$version")
builddir = joinpath(depsdir,"builds","casacore-$version")
files    = [joinpath(prefix,"lib",library.name*".so") for library in casacore_libraries]
provides(BuildProcess,
        (@build_steps begin
                GetSources(libcasa_tables)
                GetSources(libcasa_measures)
                CreateDirectory(builddir)
                @build_steps begin
                        ChangeDirectory(builddir)
                        FileRule(files,@build_steps begin
                                `cmake -DCMAKE_INSTALL_PREFIX="$prefix" $srcdir`
                                `make`
                                `make install`
                        end)
                end
        end),casacore_libraries)

builddir = joinpath(depsdir,"builds","casacorewrapper")
provides(BuildProcess,
        (@build_steps begin
                GetSources(libcasacorewrapper)
                CreateDirectory(builddir)
                @build_steps begin
                        ChangeDirectory(builddir)
                        FileRule(joinpath(prefix,"lib","libcasacorewrapper.so"),@build_steps begin
                                `make`
                                `make install`
                        end)
                end
        end),libcasacorewrapper)

@BinDeps.install Dict(:libcasacorewrapper => :libcasacorewrapper)

