const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lexical = b.dependency("lexical_cast", .{}).path("include");
    const integer = b.dependency("integer", .{}).path("include");
    const libboost_beast_dep = b.dependency("beast", .{
        .target = target,
        .optimize = optimize,
    });
    // also includes another libraries dependencies
    const libboost_beast = libboost_beast_dep.artifact("beast");

    const exe = b.addExecutable(.{
        .name = "cpp-beast",
        .target = target,
        .optimize = optimize,
    });
    exe.addCSourceFiles(.{ .files = &.{
        "main.cpp",
    }, .flags = &.{
        "-Wall",
        "-Wextra",
        "-pedantic",
        "-std=c++23",
        "-fexperimental-library",
    } });
    for (libboost_beast.root_module.include_dirs.items) |include| {
        if (include == .other_step) continue;
        exe.addIncludePath(include.path);
    }
    exe.addIncludePath(integer);
    exe.addIncludePath(lexical);
    exe.defineCMacro("BOOST_BEAST_USE_STD_STRING_VIEW", "1");
    exe.defineCMacro("BOOST_ASIO_NO_DEPRECATED", "1");
    exe.linkLibrary(libboost_beast);
    exe.linkLibCpp();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run C++ Http Server");
    run_step.dependOn(&run_cmd.step);
}
