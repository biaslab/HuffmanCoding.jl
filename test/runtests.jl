using Aqua, TestItemRunner, HuffmanCoding

if get(ENV, "RUN_AQUA", "true") == "true"
    Aqua.test_all(
        HuffmanCoding;
        deps_compat = (; check_extras = false, check_weakdeps = true),
    )
end

if isempty(ARGS)
    @run_package_tests(verbose = true)
else
    filtered_files = map(arg -> joinpath(split(arg, ':')...), ARGS)
    filter_fn = ti -> any(path -> occursin(path, ti.filename), filtered_files)
    @run_package_tests(filter = filter_fn, verbose = true)
end
