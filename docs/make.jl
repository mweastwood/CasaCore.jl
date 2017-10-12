using Documenter, CasaCore

makedocs(
    format = :html,
    sitename = "CasaCore.jl",
    authors = "Michael Eastwood",
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
    julia  = "0.5",
    target = "build",
    deps   = nothing,
    make   = nothing
)

