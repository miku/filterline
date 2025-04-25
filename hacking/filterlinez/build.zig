const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "filterlinez",
        .root_source_file = b.path("filterline.zig"),
        .target = b.graph.host,
    });

    b.installArtifact(exe);
}
