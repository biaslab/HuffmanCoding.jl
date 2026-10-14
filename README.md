# HuffmanCoding.jl

An interface template for a fixed Huffman codebook with cached bit sequences and
node paths. The package currently contains only type and function declarations.
The interface tests intentionally fail until the methods are implemented.

## Intended interface

```julia
using HuffmanCoding

weights = Dict(:a => 6, :b => 3, :c => 1)
hc = build(weights)

hc[:a]             # read-only, iterable Bool sequence
nodepath(hc, :a)   # read-only, iterable Int node IDs
keys(hc)           # supported vocabulary
haskey(hc, :a)     # vocabulary membership
length(hc)         # vocabulary size

for bit in hc[:a]
    # Use each bit.
end
```

Both sequences support indexing and `length`. A node path excludes the root and
includes the leaf: element `i` is the node reached after taking bit `i`. Node IDs
are meaningful only within their own codebook. Both lookups raise `KeyError` for
unknown objects. The codebook and its returned sequences expose no indexed
assignment.

`build(weights)` will return a `HuffmanCode` whose default tree is an
[`AbstractTrees.StableNode`](https://juliacollections.github.io/AbstractTrees.jl/stable/#Type-Stability-and-Performance).
Internal nodes have two ordered children. The codebook's `tree::T` field remains
generic, so other tree representations can also be stored. Node IDs belong to
the codebook and do not have to be array positions.

`HuffmanCode` holds the tree, a weight mapping, and an internal dictionary whose
entries contain both bits and node paths. The dictionary keys supply the
vocabulary. `build` will copy the input weight mapping: changing, adding, or
deleting its entries will leave the built codebook unchanged. Vocabulary objects
themselves are not deep-copied.

Tests use manually prepared `StableNode` fixtures through one test-only helper
that calls Julia's generated field constructor. Adding fields requires updating
that helper rather than each behavior test. Cache layout and node numbering
remain implementation details; `build` is the public construction API.

`build` and `nodepath` are methodless declarations. Weighted construction, lookup
methods, sequence containers, incremental updates, whole-message encoding, and
decoding are not implemented. Default-tree and weight-copying behavior are
specified by tests for future implementation.

## Running the tests

The test layout follows
[RxInfer.jl](https://github.com/ReactiveBayes/RxInfer.jl/blob/main/test/runtests.jl):
isolated `@testitem` blocks, verbose `TestItemRunner` discovery, optional Aqua
checks, and filename filters.

```sh
julia --project -e 'using Pkg; Pkg.test()'
```

Run only node-path tests, using a colon-separated path filter:

```sh
julia --project -e 'using Pkg; Pkg.test(test_args=["interface:nodepath_tests.jl"])'
```

Disable Aqua checks for an interface-only run:

```sh
RUN_AQUA=false julia --project -e 'using Pkg; Pkg.test()'
```

Package loading, declarations, and Aqua checks should pass. Interface tests report
ordinary failures or errors and a nonzero exit status for missing functionality;
they are not skipped or marked broken. No Huffman construction algorithm is
provided in either the source or the test fixtures.
