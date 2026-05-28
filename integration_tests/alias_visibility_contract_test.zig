const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "run",
            .aliases = &.{"go"},
            .desc = "Run command",
            .flags = &.{
                .{ .long = "--name", .aliases = &.{"--title"}, .kind = .string, .required = true },
                .{ .long = "--secret", .hidden = true, .kind = .bool, .default = .{ .bool = false } },
                .{ .long = "--old", .kind = .bool, .deprecated = .{ .message = "kept for compatibility", .replacement = "--name" } },
            },
        },
        .{
            .name = "secret",
            .hidden = true,
            .desc = "Hidden command",
        },
        .{
            .name = "legacy",
            .deprecated = .{ .message = "legacy mode is deprecated", .replacement = "run" },
            .desc = "Deprecated command",
        },
    },
};

comptime {
    cli.validate(root);
}

test "command and flag aliases parse to canonical results" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "go", "--title=demo" }, &detail);
    const args = result.match.run;
    try std.testing.expectEqualStrings("demo", args.name);
}

test "hidden commands and flags remain parseable" {
    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "secret" }, &detail);
        switch (result) {
            .match => {},
            .help => return error.ExpectedMatch,
        }
    }

    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "run", "--name", "demo", "--secret" }, &detail);
        try std.testing.expect(result.match.run.secret);
    }
}

test "generated surfaces honor visibility and deprecation metadata" {
    const help_default = comptime cli.helpText(root, &.{});
    try expectNotContains(help_default, "secret");
    try expectContains(help_default, "legacy");
    try expectContains(help_default, "deprecated");

    const help_hidden = comptime cli.helpTextWithOptions(root, &.{}, .{ .include_hidden = true });
    try expectContains(help_hidden, "secret");

    const leaf_help_default = comptime cli.helpText(root, &.{"run"});
    try expectNotContains(leaf_help_default, "--secret");
    try expectContains(leaf_help_default, "--old");
    try expectContains(leaf_help_default, "kept for compatibility");

    const completion_default = comptime cli.completion.script(root, .bash);
    try expectNotContains(completion_default, "secret");
    const completion_hidden = comptime cli.completion.scriptWithOptions(root, .bash, .{ .include_hidden = true });
    try expectContains(completion_hidden, "secret");

    const man_default = comptime cli.man.page(root, &.{}, .{});
    try expectNotContains(man_default, "Hidden command");
    try expectContains(man_default, "Deprecated");

    const schema_default = comptime cli.schema.json(root, .{});
    try expectContains(schema_default, "\"aliases\":[\"go\"]");
    try expectContains(schema_default, "\"replacement\":\"run\"");
    try expectNotContains(schema_default, "\"name\":\"secret\"");

    const schema_hidden = comptime cli.schema.json(root, .{ .include_hidden = true });
    try expectContains(schema_hidden, "\"name\":\"secret\"");
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}

fn expectNotContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) == null);
}
