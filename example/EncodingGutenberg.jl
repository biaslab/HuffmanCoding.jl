using Downloads
using HuffmanCoding

include(joinpath(@__DIR__, "PlotTree.jl"))

# Optionally pass an existing text file as the first command-line argument.
path = isempty(ARGS) ? Downloads.download(
    "https://www.gutenberg.org/cache/epub/11/pg11.txt"
) : first(ARGS)
text = read(path, String)

weights = Dict{Char,Int}()
for char in text
    weights[char] = get(weights, char, 0) + 1
end

hc = build(weights)

collect(hc['e'])             # code for 'e'
collect(nodepath(hc, 'e'))   # internal nodes for that code
svg_path = plot_tree(hc.tree; weights, title="Alice in Wonderland")
println("SVG: ", svg_path)
