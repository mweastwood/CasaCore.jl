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
    "text": "Load this module by runningusing CasaCore.TablesThe Tables module is used to interact with CasaCore tables. This is a common data format in radio astronomy. For example CASA measurement sets and CASA calibration tables are simply CasaCore tables with a standard set of columns, keywords, and subtables.Opening a table is simple:table = Table(\"/path/to/table\")This will open an existing table at the given path, or create a new table if one does not already exist at that path. Note that a read/write lock is automatically obtained on an open table. This lock will automatically be released when the table object is garbage collected, but you may manually release the lock by calling Tables.unlock(table)."
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
    "text": "If you do not want to read or write to an entire column, you can instead pick a single row of the column (ie. a cell). For example, the length of the 123rd baseline in a measurement set can be computed by:uvw = table[\"UVW\", 123]\nbaseline_length = norm(uvw)If we then perform a calculation that updates the uvw coordinates of this baseline, we can write these changes back to the table:table[\"UVW\", 123] = uvwThe number of rows in the table can be obtained with Tables.numrows(table).  Note also that the indexing order is column first, row second. This is opposite from the usual matrix convention where the first index specifies the row.important: Important\nJulia is 1-indexed programming language. This means that the first element of an array x is accessed with x[1] instead of x[0] (as is the case for C and Python). Similarly, the first row of a table is row number 1. Attempting to access row number 0 will throw a CasaCoreError because this row does not exist."
},

{
    "location": "tables.html#Keywords-1",
    "page": "CasaCore.Tables",
    "title": "Keywords",
    "category": "section",
    "text": "Keywords are accessed using the kw\"...\" string macro. For example:ms_version = table[kw\"MS_VERSION\"] # read the value of the \"MS_VERSION\" keyword\ntable[kw\"MS_VERSION\"] = 2.0        # set the value of the \"MS_VERSION\" keywordA keyword can be removed with the Tables.removekeyword! function.warning: Warning\nA current known limitation of CasaCore.jl is the inability to read from or write to keywords that contain an array of values. This will be fixed if you file a bug report!"
},

{
    "location": "tables.html#Subtables-1",
    "page": "CasaCore.Tables",
    "title": "Subtables",
    "category": "section",
    "text": "Subtables can be opened by reading their location from the appropriate keyword, and opening them as you would a regular table.location = table[kw\"SPECTRAL_WINDOW\"]\nsubtable = Table(location)In this example the SPECTRAL_WINDOW keyword contains the path to the corresponding subtable, which usually contains information about the frequency bands and channels of a measurement set."
},

{
    "location": "tables.html#Best-Practices-1",
    "page": "CasaCore.Tables",
    "title": "Best Practices",
    "category": "section",
    "text": ""
},

{
    "location": "tables.html#Type-Stability-1",
    "page": "CasaCore.Tables",
    "title": "Type Stability",
    "category": "section",
    "text": "Julia is a dynamically typed language. Because of this we can write statements like column = table[\"column\"] without knowing the type of the column ahead of time. If the column contains floats (Float32), Julia will do the right thing. If the column contains doubles (Float64), Julia will do the right thing. As a user, we did not need to know whether this column contains floats or doubles ahead of time.However Julia also performs \"type-inference\". This means that Julia will attempt to deduce the types of your variables. If the types of your variables can be inferred at compile time, Julia will generate more efficient machine code specialized on the types that it inferred. If the types of your variables cannot be inferred at compile time, Julia will need to generate less efficient generic code to account for the uncertainty in the types of your variables.This concept is important for CasaCore.Tables because the result of table[\"column\"] can be a wide variety of different types, and the actual type isn't known until run time. Now consider the following example:function add_one_to_data_column(table)\n    column = table[\"DATA\"] # type of `column` cannot be inferred\n    for idx in eachindex(column)\n        column[idx] += 1\n    end\n    table[\"DATA\"] = column\nendThis function will read the DATA column from the given table, add one to each element, and then write the result back to the table. However because the type of column cannot be inferred, the performance of the for-loop will be sub-optimal. We can remedy this problem by moving the computational kernel into a separate function:function add_one_to_data_column(table)\n    column = table[\"DATA\"]\n    do_the_for_loop(column) # `do_the_for_loop` specializes on the actual type of `column`\n    table[\"DATA\"] = column\nend\n\nfunction do_the_for_loop(column)\n    for idx in eachindex(column)\n        column[idx] += 1\n    end\nendWhen do_the_for_loop is called, Julia will specialize the function on the actual type of column. That is, the for-loop will be compiled with the knowledge of the actual type of column.  This specialization ultimately means that the latter example will generally be faster.For more information please refer to the performance tips section of the Julia manual."
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
    "text": "CurrentModule = CasaCore.MeasuresLoad this module by runningusing CasaCore.MeasuresThe Measures module is used to interface with the CasaCore measures system, which can be used to perform coordinate system conversions. For example, UTC time can be converted to atomic time, or a B1950 coordinates can be converted to J2000 coordinates.At the moment there are 3 different kinds of measures available:Epochs - representing an instance in time\nDirections - representing a direction to an object on the sky\nPositions - representing a location on the Earth"
},

{
    "location": "measures.html#Units-1",
    "page": "CasaCore.Measures",
    "title": "Units",
    "category": "section",
    "text": "CasaCore.Measures depends on the Unitful package in order to specify the units associated with various quantities. The Unitful package should have automatically been installed when you ran Pkg.add(\"CasaCore\"). You can load the Unitful package by running using Unitful and documentation for Unitful is also available. Unitful is a particularly elegant package for unit-checked computation because the unit checking occurs at compile-time. That is, there is no run-time overhead associated with using Unitful.Unitful offers two ways to attach units to a quantity:using Unitful: m\nx = 10.0 * u\"m\" # using the u\"...\" string macro\ny = 10.0 * m    # using the Unitful.m object (which we have imported into our namespace)The first approach using the string macro is generally preferred because it avoids polluting the namespace. Simply replace the ... in u\"...\" with your desired units. For example we could obtain units of meters per second by writing u\"m/s\" or radians per kilometer-squared by writing u\"rad/km^2\".CasaCore.Measures, however, will only expect quantities with three different kinds of units: times, lengths, and angles. These are summarized below.Unit Expression\nSeconds u\"s\"\nDays u\"dy\"\nMeters u\"m\"\nKilometers u\"km\"\nDegrees u\"°\"\nRadians u\"rad\"note: Note\nThe ° character for degrees con be obtained at the Julia REPL by typing \\degree and then pressing <tab>. The Julia plugins for Emacs and vim also provide this functionality."
},

{
    "location": "measures.html#CasaCore.Measures.Epoch-Tuple{CasaCore.Measures.Epochs.System,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Time}(1//1),)},U} where U where T}",
    "page": "CasaCore.Measures",
    "title": "CasaCore.Measures.Epoch",
    "category": "Method",
    "text": "Epoch(sys, time)\n\nInstantiate an epoch in the given coordinate system (sys).\n\nThe time should be given as a modified Julian date.  Additionally the Unitful package should be used to communicate the units of time.\n\nFor example time = 57365.5 * u\"d\" corresponds to a Julian date of 57365.5 days. However you can also specify the Julian date in seconds (u\"s\"), or any other unit of time supported by Unitful.\n\nCoordinate Systems:\n\nThe coordinate system is selected using the string macro epoch\"...\" where the ... is replaced with one of the coordinate systems listed below.\n\nLAST - local apparent sidereal time\nLMST - local mean sidereal time\nGMST1 - Greenwich mean sidereal time\nGAST - Greenwich apparent sidereal time\nUT1 - UT0 (raw time from GPS measurements) corrected for polar wandering\nUT2 - UT1 corrected for variable Earth rotation\nUTC - coordinated universal time\nTAI - international atomic time\nTDT - terrestrial dynamical time\nTCG - geocentric coordinate time\nTDB - barycentric dynamical time\nTCB - barycentric coordinate time\n\nExamples:\n\nusing Unitful: d\nEpoch(epoch\"UTC\",     0.0d) # 1858-11-17T00:00:00\nEpoch(epoch\"UTC\", 57365.5d) # 2015-12-09T12:00:00\n\n\n\n"
},

{
    "location": "measures.html#Epochs-1",
    "page": "CasaCore.Measures",
    "title": "Epochs",
    "category": "section",
    "text": "An epoch measure is created using the Epoch(sys, time) constructor where sys specifies the coordinate system and time specifies the Julian date.Epoch(::Epochs.System, ::Unitful.Time)"
},

{
    "location": "measures.html#CasaCore.Measures.Direction-Tuple{CasaCore.Measures.Directions.System,Unitful.Quantity{T,Unitful.Dimensions{()},U} where U where T,Unitful.Quantity{T,Unitful.Dimensions{()},U} where U where T}",
    "page": "CasaCore.Measures",
    "title": "CasaCore.Measures.Direction",
    "category": "Method",
    "text": "Direction(sys, longitude, latitude)\nDirection(sys)\n\nInstantiate a direction in the given coordinate system (sys).\n\nThe longitude and latitude may either be a sexagesimally formatted string, or an angle where the units (degrees or radians) are specified by using the Unitful package. If the longitude and latitude coordinates are not provided, they are assumed to be zero.\n\nCoordinate Systems:\n\nThe coordinate system is selected using the string macro dir\"...\" where the ... is replaced with one of the coordinate systems listed below.\n\nJ2000 - mean equator and equinox at J2000.0 (FK5)\nJMEAN - mean equator and equinox at frame epoch\nJTRUE - true equator and equinox at frame epoch\nAPP - apparent geocentric position\nB1950 - mean epoch and ecliptic at B1950.0\nB1950_VLA - mean epoch (1979.9) and ecliptic at B1950.0\nBMEAN - mean equator and equinox at frame epoch\nBTRUE - true equator and equinox at frame epoch\nGALACTIC - galactic coordinates\nHADEC - topocentric hour angle and declination\nAZEL - topocentric azimuth and elevation (N through E)\nAZELSW - topocentric azimuth and elevation (S through W)\nAZELGEO - geodetic azimuth and elevation (N through E)\nAZELSWGEO - geodetic azimuth and elevation (S through W)\nJNAT - geocentric natural frame\nECLIPTIC - ecliptic for J2000 equator and equinox\nMECLIPTIC - ecliptic for mean equator of date\nTECLIPTIC - ecliptic for true equator of date\nSUPERGAL - supergalactic coordinates\nITRF - coordinates with respect to the ITRF Earth frame\nTOPO - apparent topocentric position\nICRS - international celestial reference system\nMERCURY\nVENUS\nMARS\nJUPITER\nSATURN\nURANUS\nNEPTUNE\nPLUTO\nSUN\nMOON\n\nExamples:\n\nusing Unitful: °, rad\nDirection(dir\"AZEL\", 0°, 90°) # topocentric zenith\nDirection(dir\"ITRF\", 0rad, 1rad)\nDirection(dir\"J2000\", \"12h00m\", \"43d21m\")\nDirection(dir\"SUN\")     # the direction towards the Sun\nDirection(dir\"JUPITER\") # the direction towards Jupiter\n\n\n\n"
},

{
    "location": "measures.html#Directions-1",
    "page": "CasaCore.Measures",
    "title": "Directions",
    "category": "section",
    "text": "Direction(::Directions.System, ::Angle, ::Angle)"
},

{
    "location": "measures.html#CasaCore.Measures.Position-Tuple{CasaCore.Measures.Positions.System,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U} where U where T,Unitful.Quantity{T,Unitful.Dimensions{()},U} where U where T,Unitful.Quantity{T,Unitful.Dimensions{()},U} where U where T}",
    "page": "CasaCore.Measures",
    "title": "CasaCore.Measures.Position",
    "category": "Method",
    "text": "Position(sys, elevation, longitude, latitude)\n\nInstantiate a position in the given coordinate system (sys).\n\nNote that depending on the coordinate system the elevation may be measured relative to the center or the surface of the Earth.  In both cases the units should be given with the Unitful package.  The longitude and latitude may either be a sexagesimally formatted string, or an angle where the units (degrees or radians) are specified by using the Unitful package. If the longitude and latitude coordinates are not provided, they are assumed to be zero.\n\nCoordinate Systems:\n\nThe coordinate system is selected using the string macro pos\"...\" where the ... is replaced with one of the coordinate systems listed below.\n\nITRF - the International Terrestrial Reference Frame\nWGS84 - the World Geodetic System 1984\n\nExamples:\n\nusing Unitful: m, °\nPosition(pos\"WGS84\", 5000m, \"20d30m00s\", \"-80d00m00s\")\nPosition(pos\"WGS84\", 5000m, 20.5°, -80°)\n\n\n\n"
},

{
    "location": "measures.html#CasaCore.Measures.observatory",
    "page": "CasaCore.Measures",
    "title": "CasaCore.Measures.observatory",
    "category": "Function",
    "text": "observatory(name)\n\nGet the position of an observatory from its name.\n\nExamples:\n\nobservatory(\"VLA\")  # the Very Large Array\nobservatory(\"ALMA\") # the Atacama Large Millimeter/submillimeter Array\n\n\n\n"
},

{
    "location": "measures.html#Positions-1",
    "page": "CasaCore.Measures",
    "title": "Positions",
    "category": "section",
    "text": "Position(::Positions.System, ::Unitful.Length, ::Angle, ::Angle)\nobservatory"
},

{
    "location": "measures.html#CasaCore.Measures.ReferenceFrame",
    "page": "CasaCore.Measures",
    "title": "CasaCore.Measures.ReferenceFrame",
    "category": "Type",
    "text": "ReferenceFrame\n\nThe ReferenceFrame type contains information about the frame of reference to use when converting between coordinate systems. For example converting from J2000 coordinates to AZEL coordinates requires knowledge of the observer's location, and the current time. However converting between B1950 coordinates and J2000 coordinates requires no additional information about the observer's frame of reference.\n\nUse the set! function to add information to the given frame of reference.\n\nExample:\n\nframe = ReferenceFrame()\nset!(frame, observatory(\"VLA\")) # set the observer's position to the location of the VLA\nset!(frame, Epoch(epoch\"UTC\", 50237.29*u\"d\")) # set the current UTC time\n\n\n\n"
},

{
    "location": "measures.html#CasaCore.Measures.measure",
    "page": "CasaCore.Measures",
    "title": "CasaCore.Measures.measure",
    "category": "Function",
    "text": "measure(frame, value, newsys)\n\nConverts the value measured in the given frame of reference into a new coordinate system.\n\nArguments:\n\nframe - an instance of the ReferenceFrame type\nvalue - an Epoch, Direction, or Position that will be converted from its current           coordinate system into the new one\nnewsys - the new coordinate system\n\nNote that the reference frame must have all the required information to convert between the coordinate systems. Not all conversions require the same information!\n\nExamples:\n\n# Compute the azimuth and elevation of the Sun\nmeasure(frame, Direction(dir\"SUN\"), dir\"AZEL\")\n\n# Compute the ITRF position of the VLA\nmeasure(frame, observatory(\"VLA\"), pos\"ITRF\")\n\n# Compute the atomic time from a UTC time\nmeasure(frame, Epoch(epoch\"UTC\", 50237.29*u\"d\"), epoch\"TAI\")\n\n\n\n"
},

{
    "location": "measures.html#Coordinate-System-Conversions-1",
    "page": "CasaCore.Measures",
    "title": "Coordinate System Conversions",
    "category": "section",
    "text": "ReferenceFrame\nmeasure"
},

]}
