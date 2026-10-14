@testitem "build constructs from object weights" begin
    using DataStructures: OrderedDict

    @testset "$label" for (label, weights) in (
        ("counts", Dict(:a => 6, :b => 3, :c => 1)),
        ("probabilities", Dict("a" => 0.6, "b" => 0.3, "c" => 0.1)),
        ("ordered mapping", OrderedDict(:a => 6, :b => 3, :c => 1)),
    )
        hc = build(weights)

        @test hc isa HuffmanCode
        @test !ismutabletype(typeof(hc))
        @test Set(keys(hc)) == Set(keys(weights))
        @test length(hc) == length(weights)
        for object in keys(weights)
            @test haskey(hc, object)
            @test eltype(hc[object]) === Bool
            @test eltype(nodepath(hc, object)) === Int
            @test length(hc[object]) == length(nodepath(hc, object))
        end
    end
end

@testitem "build defaults to a binary StableNode tree" begin
    using AbstractTrees: StableNode, children, nodevalue, PreOrderDFS, Leaves

    weights = Dict(:a => 6, :b => 3, :c => 1)
    hc = build(weights)

    @test hc.tree isa StableNode
    @test all(length(children(node)) in (0, 2) for node in PreOrderDFS(hc.tree))
    leaves = collect(Leaves(hc.tree))
    @test length(leaves) == length(weights)
    @test Set(nodevalue(leaf).object for leaf in leaves) == Set(keys(weights))
    ids = [nodevalue(node).id for node in PreOrderDFS(hc.tree)]
    @test all(id isa Int for id in ids)
    @test length(unique(ids)) == length(ids)
    @test all(
        isempty(children(node)) || nodevalue(node).object === nothing
        for node in PreOrderDFS(hc.tree)
    )
end

@testitem "Built codes reach the leaves labeled with their objects" begin
    using AbstractTrees: children, nodevalue

    @testset "$label" for (label, weights) in (
        ("symbols", Dict(:a => 6, :b => 3, :c => 1)),
        ("nothing is a vocabulary object", Dict(nothing => 6, :b => 3, :c => 1)),
        ("mixed objects and tied weights", Dict("a" => 1, (:b, 2) => 1, nothing => 1, 42 => 0)),
    )
        hc = build(weights)
        for object in keys(weights)
            reached = hc.tree
            internal_ids = Int[]
            for bit in hc[object]
                @test !isempty(children(reached))
                push!(internal_ids, nodevalue(reached).id)
                reached = children(reached)[Int(bit) + 1]
            end
            @test isempty(children(reached))
            @test isequal(nodevalue(reached).object, object)
            @test collect(nodepath(hc, object)) == internal_ids
        end
    end
end

@testitem "Huffman codes have the expected optimal weighted length" begin
    weights = Dict(:a => 45, :b => 13, :c => 12, :d => 16, :e => 9, :f => 5)
    hc = build(weights)

    @test sum(weight * length(hc[object]) for (object, weight) in weights) == 224
    @test length(hc[:a]) == 1
    codes = [collect(hc[object]) for object in keys(weights)]
    @test all(
        length(a) > length(b) || a != b[1:length(a)]
        for (i, a) in enumerate(codes), (j, b) in enumerate(codes) if i != j
    )

    tied = build(Dict(object => 1 for object in (:a, :b, :c, :d)))
    @test all(length(tied[object]) == 2 for object in keys(tied))
end

@testitem "Single-object codebooks have typed empty sequences" begin
    using AbstractTrees: children, nodevalue

    hc = build(Dict(nothing => 1))
    @test length(hc) == 1
    @test haskey(hc, nothing)
    @test isempty(children(hc.tree))
    @test nodevalue(hc.tree).object === nothing
    @test isempty(hc[nothing])
    @test isempty(nodepath(hc, nothing))
    @test eltype(hc[nothing]) === Bool
    @test eltype(nodepath(hc, nothing)) === Int
    @test collect(hc[nothing]) == Bool[]
    @test collect(nodepath(hc, nothing)) == Int[]
end

@testitem "Built sequences are read-only and preserve cached values" begin
    hc = build(Dict(:a => 6, :b => 3, :c => 1))

    for object in keys(hc), lookup in (getindex, nodepath)
        sequence = lookup(hc, object)
        expected = collect(sequence)
        @test_throws Exception setindex!(sequence, sequence[1], 1)
        @test collect(lookup(hc, object)) == expected

        # Mutating a caller-owned copy must not alter the cached sequence.
        copied = collect(sequence)
        empty!(copied)
        @test collect(lookup(hc, object)) == expected
    end
    @test_throws KeyError hc[:missing]
    @test_throws KeyError nodepath(hc, :missing)
end

@testitem "Weights are validated and narrow integer sums are supported" begin
    @test_throws ArgumentError build(Dict{Symbol,Int}())
    for invalid in (-1, NaN, Inf, -Inf, 1 + im, "heavy")
        @test_throws ArgumentError build(Dict(:a => invalid, :b => 1))
    end
    @test_throws OverflowError build(Dict(:a => typemax(Int), :b => 1))
    @test_throws OverflowError build(Dict(:a => floatmax(Float64), :b => floatmax(Float64)))

    for weight in (Int8(100), true, 0)
        hc = build(Dict(:a => weight, :b => weight))
        @test Set(keys(hc)) == Set((:a, :b))
        @test length(hc[:a]) == length(hc[:b]) == 1
        @test hc[:a][1] != hc[:b][1]
    end
end

@testitem "Changing input weights leaves the codebook unchanged" begin
    using AbstractTrees: children, nodevalue, PreOrderDFS

    weights = Dict(:a => 6, :b => 3, :c => 1)
    hc = build(weights)
    vocabulary = Set(keys(hc))
    bits_before = Dict(object => collect(hc[object]) for object in vocabulary)
    paths_before = Dict(object => collect(nodepath(hc, object)) for object in vocabulary)
    tree_before = [
        (nodevalue(node), [nodevalue(child).id for child in children(node)])
        for node in PreOrderDFS(hc.tree)
    ]

    weights[:a] = 60
    delete!(weights, :b)
    weights[:d] = 10

    @test Set(keys(hc)) == vocabulary
    @test length(hc) == length(vocabulary)
    @test !haskey(hc, :d)
    @test [
        (nodevalue(node), [nodevalue(child).id for child in children(node)])
        for node in PreOrderDFS(hc.tree)
    ] == tree_before
    for object in vocabulary
        @test haskey(hc, object)
        @test collect(hc[object]) == bits_before[object]
        @test collect(nodepath(hc, object)) == paths_before[object]
    end
end
