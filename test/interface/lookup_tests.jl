@testitem "Bit lookup and iteration" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook

    (; hc) = prepared_codebook()
    @testset "$object" for (object, expected) in (
        :a => [true, false],
        :b => [true, true],
        :c => [false],
    )
        bits = hc[object]

        @test eltype(bits) === Bool
        @test collect(bits) == expected
        @test length(bits) == length(expected)
        @test [bits[i] for i in 1:length(bits)] == expected

        visited = Bool[]
        for bit in bits
            push!(visited, bit)
        end
        @test visited == expected
        @test collect(hc[object]) == expected
    end
end

@testitem "Lookup uses object keys" setup = [CodebookFixtures] begin
    using .CodebookFixtures: fixture_codebook, fixture_node

    @testset "$objects" for objects in (("a", "b"), ((:a, 1), (:b, 2)), (42, 7), (nothing, :b))
        entries = Dict(
            objects[1] => (bits = (false,), nodes = (1,)),
            objects[2] => (bits = (true,), nodes = (1,)),
        )
        S = keytype(entries)
        tree = fixture_node(S, 1, nothing, (
            fixture_node(S, 2, objects[1]),
            fixture_node(S, 3, objects[2]),
        ))
        hc = fixture_codebook(; tree, entries)

        @test collect(hc[objects[1]]) == [false]
        @test collect(hc[objects[2]]) == [true]
        @test collect(nodepath(hc, objects[1])) == [1]
        @test collect(nodepath(hc, objects[2])) == [1]
    end
end

@testitem "Unknown objects raise KeyError" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook

    (; hc) = prepared_codebook()
    @test_throws KeyError hc[:missing]
    @test_throws KeyError nodepath(hc, :missing)
end

@testitem "Codebooks do not support indexed assignment" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook

    (; hc) = prepared_codebook()
    @test_throws MethodError setindex!(hc, (false, false), :a)
end

@testitem "Bit sequences are read-only" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook

    (; hc) = prepared_codebook()
    bits = hc[:b]
    expected = collect(bits)

    @test_throws Exception setindex!(bits, false, 1)
    @test collect(bits) == expected
    @test collect(hc[:b]) == expected
end
