using NBT
using Documenter

DocMeta.setdocmeta!(NBT, :DocTestSetup, :(using NBT); recursive=true)

makedocs(;
    modules=[NBT],
    authors="Ellie <intricatebread@gmail.com> and contributors",
    repo="https://github.com/lntricate1/NBT.jl/blob/{commit}{path}#{line}",
    sitename="NBT.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://lntricate1.github.io/NBT.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/lntricate1/NBT.jl",
    devbranch="main",
)
