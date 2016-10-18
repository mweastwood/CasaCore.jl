using Documenter, CasaCore

makedocs(
    format = :html,
    sitename = "CasaCore.jl",
    pages = [
        "Introduction" => "index.md",
        "Modules" => [
            "CasaCore.Tables" => "tables.md",
            "CasaCore.Measures" => "measures.md"
        ]
    ]
)

deploydocs(
    repo   = "github.com/mweastwood/CasaCore.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)

