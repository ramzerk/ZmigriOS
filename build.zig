const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zmigriOS",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.setLinkerScript(b.path("src/linker.ld"));
    exe.root_module.link_libc = false;
    exe.pie = false;

    exe.entry = .{ .symbol_name = "_start" };
    exe.root_module.red_zone = false;

    b.installArtifact(exe);
}
