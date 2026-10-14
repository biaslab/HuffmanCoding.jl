using AbstractTrees: children, nodevalue

html_escape(value) = replace(string(value), '&' => "&amp;", '<' => "&lt;", '>' => "&gt;", '"' => "&quot;", '\'' => "&#39;")
dot_quote(value) = "\"" * replace(string(value), '\\' => "\\\\", '"' => "\\\"", '\n' => "\\n", '\r' => "\\r") * "\""

function symbol_label(object)
    object === ' ' && return "SPACE"
    object === '\n' && return "NEWLINE"
    object === '\t' && return "TAB"
    object === '\r' && return "RETURN"
    return object isa Char && isprint(object) ? string(object) : repr(object)
end

"""
    plot_tree(tree; weights=nothing, title="Huffman tree", filename=...)

Render a default Huffman tree as SVG and return the SVG file path.
Requires Graphviz's `dot` on PATH. `filename` is the output path without an
extension. Weights are optional and only add frequency labels; the displayed
structure comes directly from `tree`.
"""
function plot_tree(tree; weights=nothing, title="Huffman tree",
                   filename=joinpath(@__DIR__, "output", "huffman-tree"))
    dot = Sys.which("dot")
    isnothing(dot) && error("Install Graphviz to render the tree (on macOS: brew install graphviz).")
    mkpath(dirname(abspath(filename)))
    svgfile = abspath(filename) * ".svg"
    total = isnothing(weights) ? nothing : sum(values(weights))

    source = sprint() do io
        println(io, "digraph Huffman {")
        println(io, "graph [rankdir=LR, ordering=out, bgcolor=\"transparent\", nodesep=0.20, ranksep=0.62, pad=0.3, splines=true, label=$(dot_quote(title)), labelloc=t, labeljust=l, fontname=\"Avenir Next\", fontsize=26, fontcolor=\"#203849\"];")
        println(io, "node [fontname=\"Avenir Next\", fontsize=11, color=\"#cbd5df\", penwidth=1.1];")
        println(io, "edge [fontname=\"Avenir Next\", fontsize=12, penwidth=1.6, arrowsize=0.55];")

        function visit(node, code)
            value, branches = nodevalue(node), children(node)
            id = value.id
            if isempty(branches)
                label = html_escape(symbol_label(value.object))
                code_label = isempty(code) ? "empty code" : code
                frequency = if isnothing(weights)
                    ""
                else
                    count = weights[value.object]
                    share = total > 0 ? " · $(round(100 * (count / total); digits=2))%" : ""
                    "<TR><TD COLSPAN=\"2\"><FONT POINT-SIZE=\"10\" COLOR=\"#64748b\">$(html_escape(count))$(share)</FONT></TD></TR>"
                end
                table = """<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="3">
                    <TR><TD><FONT POINT-SIZE="18"><B>$(label)</B></FONT></TD><TD><FONT POINT-SIZE="10" COLOR="#64748b">#$(id)</FONT></TD></TR>
                    <TR><TD COLSPAN="2"><FONT FACE="Menlo" POINT-SIZE="11" COLOR="#425466">$(code_label)</FONT></TD></TR>
                    $(frequency)</TABLE>"""
                tooltip = dot_quote("$(symbol_label(value.object)) → $(code_label) · leaf $(id)")
                println(io, "n$(id) [id=\"node_$(id)\", class=\"leaf\", shape=box, style=\"rounded,filled\", fillcolor=\"#ffffff\", fontcolor=\"#172c3d\", margin=\"0.12,0.08\", tooltip=$(tooltip), label=<$(table)>];")
            else
                length(branches) == 2 || throw(ArgumentError("each internal node must have two children"))
                label = dot_quote(node === tree ? "root\n$(id)" : string(id))
                println(io, "n$(id) [id=\"node_$(id)\", shape=circle, style=filled, fillcolor=\"#203849\", color=\"#203849\", fontcolor=white, margin=0, width=0.48, label=$(label)];")
                for (index, child) in enumerate(branches)
                    child_id = nodevalue(child).id
                    bit, color = index == 1 ? ("0", "#168b83") : ("1", "#8160b4")
                    println(io, "n$(id) -> n$(child_id) [id=\"edge_$(child_id)\", label=\"$(bit)\", color=\"$(color)\", fontcolor=\"$(color)\"];")
                    visit(child, code * bit)
                end
            end
        end
        visit(tree, "")
        println(io, "}")
    end

    run(pipeline(`$dot -Tsvg -o $svgfile`; stdin=IOBuffer(source)))
    return svgfile
end
