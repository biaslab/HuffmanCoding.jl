module HuffmanCoding

using AbstractTrees: StableNode, children, nodevalue
using DataStructures: PriorityQueue

export HuffmanCode, build, nodepath

"""
    HuffmanCode

A fixed Huffman codebook containing a tree and cached encodings.
The public construction interface is [`build`](@ref).

The interface provides `hc[object]` for a read-only sequence of `Bool`
bits, `nodepath(hc, object)` for the corresponding internal-node IDs, and `keys`,
`haskey`, and `length` for vocabulary queries. Missing objects raise `KeyError`.

Use `build(weights)` to construct a codebook. The generated field constructor is
available for internal test fixtures.
Each cache entry holds both a bit sequence and an internal-node path. Cache layout
and node numbering are implementation details. The tree type is unrestricted;
`build` uses `AbstractTrees.StableNode` with labeled leaves by default.
"""
struct HuffmanCode{S,T,E}
    tree::T
    entries::Dict{S,E}
end

# Tuple storage prevents mutation; T preserves the element type for empty codes.
struct ReadOnlySequence{T} <: AbstractVector{T}
    values::Tuple{Vararg{T}}
end

Base.size(sequence::ReadOnlySequence) = (length(sequence.values),)
Base.getindex(sequence::ReadOnlySequence, index::Int) = sequence.values[index]
Base.IndexStyle(::Type{<:ReadOnlySequence}) = IndexLinear()

Base.getindex(hc::HuffmanCode, object) = hc.entries[object].bits
Base.keys(hc::HuffmanCode) = keys(hc.entries)
Base.haskey(hc::HuffmanCode, object) = haskey(hc.entries, object)
Base.length(hc::HuffmanCode) = length(hc.entries)

"""
    build(weights::AbstractDict)

Build a fixed codebook from an object-to-weight mapping. By default, its tree is
an `AbstractTrees.StableNode` with two ordered children per internal node.
Other tree representations can be stored in `HuffmanCode`.

For the default tree, `AbstractTrees.nodevalue(node)` has an `id::Int` and an
`object`. Each leaf stores its vocabulary object; internal nodes store `nothing`
in `object`. A leaf is identified by having no children, so `nothing` itself can
also be a vocabulary object. Each vocabulary object labels exactly one leaf.
Following `hc[object]` from the root (false = first child, true = second child)
must reach the leaf labeled with that object. `nodepath` contains the IDs of the
internal nodes where those bits are chosen, before following each branch.

Weights are construction input and are not retained in the codebook. Replacing,
adding, or deleting entries in the input dictionary must not change the built
tree, vocabulary, bits, or node paths. Vocabulary objects are not deep-copied.

The mapping must be nonempty and weights must be finite, nonnegative real
numbers. A single-object vocabulary has an empty code and an empty node path.
Equal weights may produce different, equally optimal codes; branch orientation
and node numbering are not guaranteed across builds.
"""
function build(weights::AbstractDict{C,F}) where {C,F}
    isempty(weights) && throw(ArgumentError("weights must not be empty"))

    Payload = NamedTuple{(:id, :object),Tuple{Int,Union{Nothing,C}}}
    Node = StableNode{Payload}
    # Widen small integer weights so their sums can be stored in the queue.
    Weight = promote_type(F, Int)
    queue = PriorityQueue{Node,Weight}(Base.Order.Forward)
    next_id = 0

    # Start with one leaf per vocabulary object.
    for (object, weight) in weights
        weight isa Real && isfinite(weight) && weight >= 0 ||
            throw(ArgumentError("weights must be finite, nonnegative real numbers"))
        next_id += 1
        leaf = Node(Payload((next_id, object)), ())
        push!(queue, leaf => weight)
    end

    # Merge the two lightest trees until only the root remains.
    while length(queue) > 1
        left, left_weight = popfirst!(queue)
        right, right_weight = popfirst!(queue)
        weight = left_weight + right_weight
        isfinite(weight) && weight >= max(left_weight, right_weight) ||
            throw(OverflowError("combined Huffman weight overflowed"))
        next_id += 1
        parent = Node(Payload((next_id, nothing)), (left, right))
        push!(queue, parent => weight)
    end

    tree, _ = popfirst!(queue)
    Entry = NamedTuple{(:bits, :nodes),Tuple{ReadOnlySequence{Bool},ReadOnlySequence{Int}}}
    entries = Dict{C,Entry}()
    cache_entries!(entries, tree, Bool[], Int[])
    return HuffmanCode(tree, entries)
end

function cache_entries!(entries, node, bits, path)
    branches = children(node)
    if isempty(branches)
        # Each leaf gets its own immutable snapshot of the traversal buffers.
        entries[nodevalue(node).object] = (
            bits = ReadOnlySequence{Bool}(Tuple(bits)),
            nodes = ReadOnlySequence{Int}(Tuple(path)),
        )
        return nothing
    end

    # The path records where a bit is chosen, before descending to the child.
    push!(path, nodevalue(node).id)
    for (index, child) in enumerate(branches)
        push!(bits, index == 2)
        cache_entries!(entries, child, bits, path)
        pop!(bits)
    end
    pop!(path)
    return nothing
end

"""
    nodepath(hc::HuffmanCode, object)

Return a read-only, iterable sequence of `Int` internal-node IDs for `object`.
Element `i` identifies the node where bit `i` in `hc[object]` chooses a child.
For a nonempty code, the path includes the root and excludes the leaf, with one
internal node per bit. Both sequences support indexing and `length`. Unknown
objects raise `KeyError`. Node IDs are meaningful only within their own codebook.

"""
nodepath(hc::HuffmanCode, object) = hc.entries[object].nodes

end
