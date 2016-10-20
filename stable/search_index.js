var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#CasaCore.jl-1",
    "page": "Introduction",
    "title": "CasaCore.jl",
    "category": "section",
    "text": "CasaCore.jl is a Julia wrapper of CasaCore, which is a commonly used library in radio astronomy.Functionality is divided into two submodules:CasaCore.Tables for interfacing with tables (for example Casa measurement sets), and\nCasaCore.Measures for performing coordinate system conversions (for example calculating the azimuth and elevation of an astronomical target)."
},

{
    "location": "index.html#Getting-Started-1",
    "page": "Introduction",
    "title": "Getting Started",
    "category": "section",
    "text": "Prior to using this package, the CasaCore library must be installed on your machine. The header and shared library files must either be located in a standard location or the corresponding directories must be added to the appropriate system path environment variable.Additionally you must also have v0.5 of the Julia programming language. CasaCore.jl makes use of features that are not present in v0.4 or lower. Download and install the latest version of Julia from the Julia language website.Finally you may obtain CasaCore.jl by running (from within the Julia REPL):Pkg.add(\"CasaCore\")  # download CasaCore.jl and attempt to build the wrapper\nPkg.test(\"CasaCore\") # test that CasaCore.jl is working properlyIf Pkg.add(\"CasaCore\") fails with a build error, you may need to make sure that the CasaCore libraries are installed and can be found by your C++ compiler. You can attempt to re-build the CasaCore.jl wrapper by running Pkg.build(\"CasaCore\"), but this is only necessary if the first attempt failed.If CasaCore.jl was built successfully but any (or all) of the tests fail after running Pkg.test(\"CasaCore\"), please open a Github issue."
},

{
    "location": "index.html#Bugs-and-Feature-Requests-1",
    "page": "Introduction",
    "title": "Bugs and Feature Requests",
    "category": "section",
    "text": "Development of this package is ongoing and largely focused on my own requirements.  If you need additional features, open an issue or a pull request.  In the short term, you can use the excellent PyCall package to access the Python wrapper of CasaCore (python-casacore)."
},

{
    "location": "tables.html#",
    "page": "CasaCore.Tables",
    "title": "CasaCore.Tables",
    "category": "page",
    "text": ""
},

{
    "location": "tables.html#CasaCore.Tables-1",
    "page": "CasaCore.Tables",
    "title": "CasaCore.Tables",
    "category": "section",
    "text": "Load this module by running using CasaCore.Tables.The Tables module is used to interact with CasaCore tables. This is a common data format in radio astronomy. For example CASA measurement sets and CASA calibration tables are simply CasaCore tables with a standard set of columns, keywords, and subtables.Opening a table is simple:table = Table(\"/path/to/table\")This will open an existing table at the given path, or create a new table if one does not already exist at that path. Note that a read/write lock is automatically obtained on an open table. This lock will automatically be released when the table object is garbage collected, but you may manually release the lock by calling Tables.unlock(table)."
},

{
    "location": "tables.html#Columns-1",
    "page": "CasaCore.Tables",
    "title": "Columns",
    "category": "section",
    "text": "Columns are accessed by name. For example to read the entire DATA column from a measurement set:table = Table(\"/path/to/measurementset.ms\")\ndata = table[\"DATA\"]If we have some function calibrate that solves for and applies a calibration to the measured visibilities, we can then write the calibrated data back to the CORRECTED_DATA column as follows:corrected_data = calibrate(data) # calibrate the measured visibilities\ntable[\"CORRECTED_DATA\"] = corrected_dataNote that the CORRECTED_DATA column will be created in the table if it does not already exist. If the column does already exist, the column will be overwritten with the contents of corrected_data.warning: Warning\nCasaCore.jl will throw a CasaCoreError exception if you try to overwrite a column with an array of the incorrect size or element type. A column that contains floats cannot be overwritten with an array of ints.A column can be removed from the table by using Tables.removecolumn!(table, \"name\"), where \"name\" is the name of the column to be removed from the table."
},

{
    "location": "tables.html#Cells-1",
    "page": "CasaCore.Tables",
    "title": "Cells",
    "category": "section",
    "text": "If you do not want to read or write to an entire column, you can instead pick a single row of the column (ie. a cell). For example, the length of the 123rd baseline in a measurement set can be computed by:uvw = table[\"UVW\", 123]\nbaseline_length = norm(uvw)If we then perform a calculation that updates the uvw coordinates of this baseline, we can write these changes back to the table:table[\"UVW\", 123] = uvwThe number of rows in the table can be obtained with Tables.numrows(table).  Note also that the indexing order is column first, row second. This is opposite from the usual matrix convention where the first index specifies the row.warning: Warning\nJulia is 1-indexed programming language. This means that the first element of an array x is accessed with x[1] instead of x[0] (as is the case for C and Python). Similarly, the first row of a table is row number 1. Attempting to access row number 0 will throw a CasaCoreError because this row does not exist."
},

{
    "location": "tables.html#Keywords-1",
    "page": "CasaCore.Tables",
    "title": "Keywords",
    "category": "section",
    "text": "Keywords are accessed using the kw\"...\" string macro. For example:ms_version = table[kw\"MS_VERSION\"]\ntable[kw\"MS_VERSION\"] = 2.0"
},

{
    "location": "tables.html#Subtables-1",
    "page": "CasaCore.Tables",
    "title": "Subtables",
    "category": "section",
    "text": "Subtables can be opened by reading their location from the appropriate keyword, and opening them as you would a regular table.location = table[kw\"SPECTRAL_WINDOW\"]\nsubtable = Table(location)"
},

{
    "location": "measures.html#",
    "page": "CasaCore.Measures",
    "title": "CasaCore.Measures",
    "category": "page",
    "text": ""
},

{
    "location": "measures.html#Measures-1",
    "page": "CasaCore.Measures",
    "title": "Measures",
    "category": "section",
    "text": "using CasaCore.Measures"
},

{
    "location": "measures.html#Epochs-1",
    "page": "CasaCore.Measures",
    "title": "Epochs",
    "category": "section",
    "text": "An Epoch represents an instance in time.epoch = Epoch(epoch\"UTC\", time * days)The first argument specifies the coordinate system.\nThe second argument specifies the time as a modified Julian date.Recognized Coordinate Systems: LAST, LMST, GMST1, GAST, UT1, UT2, UTC, TAI, TDT, TCG, TDB, TCB"
},

{
    "location": "measures.html#Directions-1",
    "page": "CasaCore.Measures",
    "title": "Directions",
    "category": "section",
    "text": "A Direction represents a position on the sky.direction = Direction(dir\"J2000\", \"19h59m28.35663s\", \"+40d44m02.0970s\")The first argument specifies the coordinate system.\nThe second argument specifies the longitude.\nThe third argument specifies the latitude.Alternatively the location of a known solar system object (see the list below) may be obtained by using:direction = Direction(dir\"JUPITER\")Recognized Coordinate Systems: J2000, JMEAN, JTRUE, APP, B1950, B1950_VLA, BMEAN, BTRUE, GALACTIC, HADEC, AZEL, AZELSW, AZELGEO, AZELSWGEO, JNAT, ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF, TOPO, ICRS, MERCURY, VENUS, MARS, JUPITER, SATURN, URANUS, NEPTUNE, PLUTO, SUN, MOON"
},

{
    "location": "measures.html#Positions-1",
    "page": "CasaCore.Measures",
    "title": "Positions",
    "category": "section",
    "text": "A Position represents a location on the Earth.Alternatively the position of a known observatory may be obtained by using:position = observatory(\"VLA\")Recognized Coordinate Systems: ITRF, WGS84"
},

{
    "location": "measures.html#Baselines-1",
    "page": "CasaCore.Measures",
    "title": "Baselines",
    "category": "section",
    "text": "Recognized Coordinate Systems: J2000, JMEAN, JTRUE, APP, B1950, B1950_VLA, BMEAN, BTRUE, GALACTIC, HADEC, AZEL, AZELSW, AZELGEO, AZELSWGEO, JNAT, ECLIPTIC, MECLIPTIC, TECLIPTIC, SUPERGAL, ITRF, TOPO, ICRS"
},

{
    "location": "measures.html#Coordinate-System-Conversions-1",
    "page": "CasaCore.Measures",
    "title": "Coordinate System Conversions",
    "category": "section",
    "text": "Some coordinate conversions require information about the associated frame of reference. For example, the conversion from a J2000 right ascension and declination to a local azimuth and elevation requires information about the observer's time and location.Here are a few examples attaching information to a frame of reference:frame = ReferenceFrame()\nposition = observatory(\"VLA\")\ntime = Epoch(epoch\"UTC\", 50237.29days))\nset!(frame, position)\nset!(frame, time)frame = ReferenceFrame()\nset!(frame, observatory(\"ALMA\"))In general, the amount of information required depends on the specific coordinate system conversion. Converting between B1950 and J2000, for example, requires no additional information about your frame of reference.Once you have established the correct frame of reference, the conversion is performed as follows:azel_direction = measure(frame, j2000_direction, dir\"AZEL\")itrf_position = measure(frame, wgs84_position, pos\"ITRF\")"
},

]}
