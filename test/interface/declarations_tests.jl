@testitem "Public declarations" setup = [CodebookFixtures] begin
    using .CodebookFixtures: prepared_codebook

    (; hc, tree) = prepared_codebook()
    @test :HuffmanCode in names(HuffmanCoding)
    @test :build in names(HuffmanCoding)
    @test :nodepath in names(HuffmanCoding)
    @test hc isa HuffmanCode
    @test !ismutabletype(typeof(hc))
    @test hc.tree === tree
end

@testitem "Codebooks accept other tree representations" setup = [CodebookFixtures] begin
    using .CodebookFixtures: fixture_codebook

    # Arrays also implement AbstractTrees; their leaves are the symbols here.
    tree = [:a, :b]
    entries = Dict(
        :a => (bits = (false,), nodes = (1,)),
        :b => (bits = (true,), nodes = (1,)),
    )
    hc = fixture_codebook(; tree, entries)

    @test hc isa HuffmanCode
    @test hc.tree === tree
end
