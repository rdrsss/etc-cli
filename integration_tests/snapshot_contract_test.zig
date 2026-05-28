const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .desc = "Snapshot tool",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .desc = "Verbose output", .kind = .bool, .default = .{ .bool = false } },
    },
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run target",
            .flags = &.{
                .{ .long = "--name", .kind = .string, .desc = "Target name", .value_name = "NAME" },
            },
            .positionals = &.{
                .{ .name = "target", .desc = "Target id", .kind = .string },
            },
            .doc = .{
                .examples = &.{.{ .title = "Run", .command = "tool run --name demo alpha", .desc = "Runs alpha." }},
                .exit_codes = &.{.{ .code = 0, .desc = "Success." }},
                .see_also = &.{"tool(1)"},
                .homepage = "https://example.test/tool",
                .license = "MIT",
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "man page golden snapshot stays stable" {
    const text = comptime cli.man.page(root, &.{}, .{});
    try std.testing.expectEqualStrings(@embedFile("snapshots/man/tool.1"), text);
}

test "help golden snapshot stays stable" {
    const text = comptime cli.helpText(root, &.{});
    try std.testing.expectEqualStrings(@embedFile("snapshots/help/tool.txt"), text);
}

test "bash completion golden snapshot covers core structure" {
    const text = comptime cli.completion.script(root, .bash);
    const snapshot = @embedFile("snapshots/completion/tool.bash");
    try expectContains(text, snapshot);
}

test "schema golden snapshot covers agent-facing contract" {
    const text = comptime cli.schema.json(root, .{});
    const snapshot = @embedFile("snapshots/schema/tool.schema.json");
    try expectContains(text, snapshot);
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    const trimmed = std.mem.trim(u8, needle, "\n\r");
    try std.testing.expect(std.mem.indexOf(u8, haystack, trimmed) != null);
}
