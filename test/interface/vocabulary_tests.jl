@testitem "Supported vocabulary" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook

    (; hc) = prepared_codebook()
    @test Set(keys(hc)) == Set((:a, :b, :c))
    @test length(hc) == 3
    @test haskey(hc, :a)
    @test haskey(hc, :b)
    @test haskey(hc, :c)
    @test !haskey(hc, :missing)
end

@testitem "Tree leaves identify the vocabulary without a separate mapping" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook, fixture_node
    using AbstractTrees: children, nodevalue, PreOrderDFS, Leaves

    (; tree) = prepared_codebook()
    leaves = collect(Leaves(tree))
    @test Set(nodevalue(leaf).object for leaf in leaves) == Set((:a, :b, :c))
    @test length(leaves) == 3
    @test all(length(children(node)) in (0, 2) for node in PreOrderDFS(tree))

    # These paths are fixture data, independent of lookup methods.
    for (object, bits, expected_ids) in (
        (:a, (true, false), [5, 4]),
        (:b, (true, true), [5, 4]),
        (:c, (false,), [5]),
    )
        reached = tree
        ids = Int[]
        for bit in bits
            push!(ids, nodevalue(reached).id)
            reached = children(reached)[Int(bit) + 1]
        end
        @test isempty(children(reached))
        @test nodevalue(reached).object === object
        @test ids == expected_ids
    end

    nothing_leaf = fixture_node(Nothing, 1, nothing)
    @test isempty(children(nothing_leaf))
    @test nodevalue(nothing_leaf).object === nothing
end
