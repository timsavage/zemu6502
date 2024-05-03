const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //** Dependencies ****

    const yaml_dep = b.dependency("yaml", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    // const raylib_math = raylib_dep.module("raylib-math");
    const raylib_artifact = raylib_dep.artifact("raylib");

    //** Main executable ****

    const exe = b.addExecutable(.{
        .name = "zemu6502",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{
            .path = "src/main.zig",
        },
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("yaml", yaml_dep.module("yaml"));
    exe.root_module.addImport("raylib", raylib);
    exe.linkLibrary(raylib_artifact);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the emulator");
    run_step.dependOn(&run_cmd.step);

    //** Unit tests ****

    const unit_tests = b.addTest(.{
        .root_source_file = .{
            .path = "src/main.zig",
        },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.root_module.addImport("yaml", yaml_dep.module("yaml"));
    unit_tests.root_module.addImport("raylib", raylib_dep.module("raylib"));
    unit_tests.linkLibC();
    unit_tests.linkLibrary(raylib_artifact);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
