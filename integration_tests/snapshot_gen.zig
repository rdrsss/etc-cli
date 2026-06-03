//! Regenerates the golden snapshot files under `integration_tests/snapshots/`
//! from the shared `snapshot_tree.zig` command tree.
//!
//! Run via `zig build snapshots-update`. The build step anchors the working
//! directory to the repo root; the snapshot subdirectories already exist, so
//! this only rewrites files.

const std = @import("std");
const cli = @import("cli");
const tree = @import("snapshot_tree.zig");

const root = tree.root;

const Artifact = struct {
    path: []const u8,
    data: []const u8,
};

const artifacts = [_]Artifact{
    .{ .path = "integration_tests/snapshots/man/tool.1", .data = cli.man.page(root, &.{}, .{}) },
    .{ .path = "integration_tests/snapshots/help/tool.txt", .data = cli.helpText(root, &.{}) },
    .{ .path = "integration_tests/snapshots/completion/tool.bash", .data = cli.completion.script(root, .bash) },
    .{ .path = "integration_tests/snapshots/completion/_tool", .data = cli.completion.script(root, .zsh) },
    .{ .path = "integration_tests/snapshots/completion/tool.fish", .data = cli.completion.script(root, .fish) },
    .{ .path = "integration_tests/snapshots/schema/tool.schema.json", .data = cli.schema.json(root, .{}) },
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const dir = std.Io.Dir.cwd();
    inline for (artifacts) |artifact| {
        try dir.writeFile(io, .{ .sub_path = artifact.path, .data = artifact.data });
        std.debug.print("wrote {s}\n", .{artifact.path});
    }
}
