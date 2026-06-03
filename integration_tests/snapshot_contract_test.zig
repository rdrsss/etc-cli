const std = @import("std");
const cli = @import("cli");
const tree = @import("snapshot_tree.zig");

const root = tree.root;

comptime {
    cli.validate(root);
}

// Golden snapshots are full-output, exact-match contracts. Regenerate them
// with `zig build snapshots-update` whenever a change intentionally alters
// generated output, and review the diff.

test "man page golden snapshot stays stable" {
    const text = comptime cli.man.page(root, &.{}, .{});
    try std.testing.expectEqualStrings(@embedFile("snapshots/man/tool.1"), text);
}

test "help golden snapshot stays stable" {
    const text = comptime cli.helpText(root, &.{});
    try std.testing.expectEqualStrings(@embedFile("snapshots/help/tool.txt"), text);
}

test "bash completion golden snapshot stays stable" {
    const text = comptime cli.completion.script(root, .bash);
    try std.testing.expectEqualStrings(@embedFile("snapshots/completion/tool.bash"), text);
}

test "zsh completion golden snapshot stays stable" {
    const text = comptime cli.completion.script(root, .zsh);
    try std.testing.expectEqualStrings(@embedFile("snapshots/completion/_tool"), text);
}

test "fish completion golden snapshot stays stable" {
    const text = comptime cli.completion.script(root, .fish);
    try std.testing.expectEqualStrings(@embedFile("snapshots/completion/tool.fish"), text);
}

test "schema golden snapshot stays stable" {
    const text = comptime cli.schema.json(root, .{});
    try std.testing.expectEqualStrings(@embedFile("snapshots/schema/tool.schema.json"), text);
}
