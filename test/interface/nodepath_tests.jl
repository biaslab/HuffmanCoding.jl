@testitem "Internal-node lookup and iteration" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook
    using AbstractTrees: nodevalue, Leaves

    (; hc, tree) = prepared_codebook()
    leaf_ids = Set(nodevalue(leaf).id for leaf in Leaves(tree))
    @testset "$object" for (object, expected) in (
        :a => [5, 4],
        :b => [5, 4],
        :c => [5],
    )
        path = nodepath(hc, object)

        @test eltype(path) === Int
        @test collect(path) == expected
        @test length(path) == length(expected)
        @test [path[i] for i in 1:length(path)] == expected

        visited = Int[]
        for node in path
            push!(visited, node)
        end
        @test visited == expected
        @test path[1] == nodevalue(tree).id
        @test all(id ∉ leaf_ids for id in path)
        @test collect(nodepath(hc, object)) == expected
    end
end

@testitem "Paths identify internal nodes before each bit" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook
    using AbstractTrees: children, nodevalue

    (; hc, tree) = prepared_codebook()
    @testset "$object" for object in (:a, :b, :c)
        bits = hc[object]
        path = nodepath(hc, object)
        @test length(bits) == length(path)

        parent = tree
        for (bit, node) in zip(bits, path)
            @test !isempty(children(parent))
            @test nodevalue(parent).id == node
            parent = children(parent)[Int(bit) + 1]
        end
        @test isempty(children(parent))
        @test nodevalue(parent).object == object
    end

    @test hc[:a][1] == hc[:b][1]
    @test hc[:a][2] != hc[:b][2]
    @test collect(nodepath(hc, :a)) == collect(nodepath(hc, :b))
end

@testitem "Node paths are read-only" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook

    (; hc) = prepared_codebook()
    path = nodepath(hc, :b)
    expected = collect(path)

    @test_throws Exception setindex!(path, 99, 1)
    @test collect(path) == expected
    @test collect(nodepath(hc, :b)) == expected
end
