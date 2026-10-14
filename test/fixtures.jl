@testmodule CodebookFixtures begin
    using HuffmanCoding
    using AbstractTrees: StableNode

    # Only this test helper depends on the codebook's field constructor.
    function fixture_codebook(; tree, entries)
        return HuffmanCode(tree, entries)
    end

    function fixture_node(::Type{S}, id::Int, object, children = ()) where {S}
        Payload = NamedTuple{(:id, :object),Tuple{Int,Union{Nothing,S}}}
        return StableNode{Payload}(Payload((id, object)), children)
    end

    function prepared_codebook()
        # IDs and branch orientation describe this fixture only.
        # Leaves carry their vocabulary objects directly in the node values.
        #
        # root 5 --0--> leaf 3 (:c)
        #        --1--> node 4 --0--> leaf 1 (:a)
        #                     --1--> leaf 2 (:b)
        tree = fixture_node(Symbol, 5, nothing, (
            fixture_node(Symbol, 3, :c),
            fixture_node(Symbol, 4, nothing, (
                fixture_node(Symbol, 1, :a),
                fixture_node(Symbol, 2, :b),
            )),
        ))
        entries = Dict(
            :a => (bits = (true, false), nodes = (5, 4)),
            :b => (bits = (true, true), nodes = (5, 4)),
            :c => (bits = (false,), nodes = (5,)),
        )
        hc = fixture_codebook(; tree, entries)
        return (; hc, tree)
    end
end
