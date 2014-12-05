using BinDeps
@BinDeps.setup

# For now we will assume that CasaCore has been built.
# However, we still need to download the header files
# from CasaCore to compile the wrapper.

version = "1.7.0"
url = "ftp://ftp.atnf.csiro.au/pub/software/casacore/casacore-$version.tar.bz2"

libcasacorewrapper = library_dependency("libcasacorewrapper")
provides(Sources, URI(url), libcasacorewrapper, unpacked_dir="casacore-$version")

depsdir  = BinDeps.depsdir(libcasacorewrapper)
prefix   = joinpath(depsdir,"usr")
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

