package("flann")

    set_homepage("https://github.com/flann-lib/flann/")
    set_description("Fast Library for Approximate Nearest Neighbors")
    set_license("BSD-3-Clause")

    add_urls("https://github.com/flann-lib/flann/archive/refs/tags/$(version).tar.gz",
             "https://github.com/flann-lib/flann.git")
    add_versions("1.9.1", "b23b5f4e71139faa3bcb39e6bbcc76967fbaf308c4ee9d4f5bfbeceaa76cc5d3")

    add_patches("1.9.1", path.join(os.scriptdir(), "patches", "1.9.1", "cuda10.patch"), "087492b422362f42c83b320296d9af7b22023cf20d81ea7bd99efabd1535f7d6")

    add_configs("with_cuda", {description = "Enable cuda build.", default = false, type = "boolean"})

    add_deps("cmake", "lz4")
    on_load("windows", "linux", "macosx", function (package)
        if package:is_plat("windows") and not package:config("shared") then
            package:add("defines", "FLANN_STATIC")
        end
        if package:config("with_cuda") then
            package:add("deps", "cuda", {system = true})
        end
    end)

    on_install("windows", "linux", "macosx", function (package)
        os.cd("src/cpp")
        io.replace("flann/defines.h", "#ifdef WIN32", "#ifdef _WIN32", {plain = true})
        io.writefile("xmake.lua", format([[
            add_rules("mode.debug", "mode.release")
            add_requires("lz4")
            if is_plat("windows") then
                if is_kind("static") then
                    add_defines("FLANN_STATIC")
                elseif is_kind("shared") then
                    add_defines("FLANN_EXPORTS")
                end
                add_cxxflags("/bigobj")
            end
            target("flann")
                set_kind("$(kind)")
                add_files("flann/flann.cpp")
                add_includedirs(".")
                add_includedirs("flann")
                add_packages("lz4")
                add_headerfiles("(flann/config.h)", "(flann/defines.h)", "(flann/flann.h)")
                add_headerfiles("(flann/flann.hpp)", "(flann/general.h)", "(flann/algorithms/*.h)", "(flann/io/*.h)", "(flann/nn/*.h)", "(flann/util/*.h)")
            target("flann_cuda")
                set_enabled(%s)
                set_kind("$(kind)")
                add_files("flann/algorithms/*.cu")
                add_defines("FLANN_USE_CUDA")
                add_includedirs(".")
                add_includedirs("flann")
                add_packages("lz4")
        ]], package:config("with_cuda") and "true" or "false"))
        local configs = {kind = package:config("shared") and "shared" or "static"}
        if package:config("with_cuda") then
            package:add("defines", "FLANN_USE_CUDA")
        end
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("flann_find_nearest_neighbors_index", {includes = "flann/flann.h"}))
    end)
