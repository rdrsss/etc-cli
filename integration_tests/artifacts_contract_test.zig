const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .desc = "Artifact helper fixture",
    .cmds = &.{
        .{
            .name = "group",
            .desc = "Parent command",
            .cmds = &.{
                .{
                    .name = "run",
                    .desc = "Run command",
                    .flags = &.{
                        .{ .long = "--name", .kind = .string, .required = true },
                    },
                },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "artifact names are deterministic" {
    try std.testing.expectEqualStrings("tool.1", comptime cli.artifacts.manFileName(root, &.{}));
    try std.testing.expectEqualStrings("tool-group-run.1", comptime cli.artifacts.manFileName(root, &.{ "group", "run" }));
    try std.testing.expectEqualStrings("tool.bash", comptime cli.artifacts.completionFileName(root, .bash));
    try std.testing.expectEqualStrings("_tool", comptime cli.artifacts.completionFileName(root, .zsh));
    try std.testing.expectEqualStrings("tool.fish", comptime cli.artifacts.completionFileName(root, .fish));
    try std.testing.expectEqualStrings("tool.schema.json", comptime cli.artifacts.schemaFileName(root));
}

test "artifact helpers return expected generated content" {
    const man = comptime cli.artifacts.manPage(root, &.{ "group", "run" }, .{});
    try std.testing.expectEqualStrings("tool-group-run.1", man.name);
    try expectContains(man.data, ".TH \"tool-group-run\" \"1\"");

    const pages = comptime cli.artifacts.allManPages(root, .{});
    try std.testing.expectEqual(@as(usize, 3), pages.len);
    try std.testing.expectEqualStrings("tool.1", pages[0].name);
    try std.testing.expectEqualStrings("tool-group.1", pages[1].name);
    try std.testing.expectEqualStrings("tool-group-run.1", pages[2].name);

    const completion = comptime cli.artifacts.completionScript(root, .bash);
    try std.testing.expectEqualStrings("tool.bash", completion.name);
    try expectContains(completion.data, "complete -F _tool tool");

    const schema = comptime cli.artifacts.schemaJson(root, .{});
    try std.testing.expectEqualStrings("tool.schema.json", schema.name);
    try expectContains(schema.data, "\"schemaVersion\":1");
}

test "normal helper usage is filesystem-free" {
    const schema = comptime cli.artifacts.schemaJson(root, .{});
    try std.testing.expect(schema.data.len > 0);
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}
