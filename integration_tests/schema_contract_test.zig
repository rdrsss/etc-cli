const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .desc = "Short root description",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .desc = "Verbose output", .kind = .bool, .default = .{ .bool = false } },
    },
    .cmds = &.{
        .{
            .name = "group",
            .desc = "Parent command",
            .flags = &.{
                .{ .long = "--mode", .desc = "Mode selector", .kind = .string },
            },
            .cmds = &.{
                .{
                    .name = "run",
                    .desc = "Run leaf",
                    .long_desc = "Run leaf with structured metadata.",
                    .flags = &.{
                        .{ .long = "--name", .desc = "Name value", .kind = .string, .value_name = "NAME", .required = true, .env = "TOOL_NAME" },
                        .{ .long = "--count", .short = 'c', .desc = "Count value", .kind = .int, .default = .{ .int = 1 } },
                    },
                    .positionals = &.{
                        .{ .name = "target", .desc = "Target name", .kind = .string },
                    },
                    .doc = .{
                        .examples = &.{
                            .{ .title = "Run target", .command = "tool group run --name demo target", .desc = "Runs a target." },
                        },
                        .exit_codes = &.{
                            .{ .code = 0, .desc = "Success." },
                            .{ .code = 2, .desc = "Invalid input." },
                        },
                        .notes = &.{"Use schema output for agents."},
                        .see_also = &.{ "tool(1)", "tool-group-run(1)" },
                        .files = &.{ "~/.config/tool/config.toml" },
                        .bugs = &.{ "Report issues at https://example.test/tool/issues." },
                        .authors = &.{ "Example Maintainers" },
                        .homepage = "https://example.test/tool",
                        .license = "MIT",
                        .copyright = "Copyright 2026 Example Maintainers.",
                        .version = "1.2.3",
                        .source_url = "https://example.test/tool.git",
                    },
                },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "schema json exposes flat command contract" {
    const text = comptime cli.schema.json(root, .{});

    try expectContains(text, "\"schemaVersion\":1");
    try expectContains(text, "\"layout\":\"flat\"");
    try expectContains(text, "\"root\":\"tool\"");
    try expectContains(text, "\"path\":[]");
    try expectContains(text, "\"path\":[\"group\",\"run\"]");
    try expectContains(text, "\"command\":\"tool group run\"");
    try expectContains(text, "\"subcommands\":[\"group\"]");
    try expectContains(text, "\"long\":\"--verbose\"");
    try expectContains(text, "\"source\":\"inherited\"");
    try expectContains(text, "\"long\":\"--name\"");
    try expectContains(text, "\"valueName\":\"NAME\"");
    try expectContains(text, "\"env\":\"TOOL_NAME\"");
    try expectContains(text, "\"envBehavior\":\"metadata-only\"");
    try expectContains(text, "\"positionals\":[{\"name\":\"target\"");
    try expectContains(text, "\"examples\":[{\"title\":\"Run target\"");
    try expectContains(text, "\"exitCodes\":[{\"code\":0");
    try expectContains(text, "\"seeAlso\":[\"tool(1)\",\"tool-group-run(1)\"]");
    try expectContains(text, "\"files\":[\"~/.config/tool/config.toml\"]");
    try expectContains(text, "\"bugs\":[\"Report issues at https://example.test/tool/issues.\"]");
    try expectContains(text, "\"authors\":[\"Example Maintainers\"]");
    try expectContains(text, "\"homepage\":\"https://example.test/tool\"");
    try expectContains(text, "\"license\":\"MIT\"");
    try expectContains(text, "\"copyright\":\"Copyright 2026 Example Maintainers.\"");
    try expectContains(text, "\"version\":\"1.2.3\"");
    try expectContains(text, "\"sourceUrl\":\"https://example.test/tool.git\"");
}

test "schema options can omit inherited flags and docs" {
    const text = comptime cli.schema.json(root, .{
        .include_inherited_flags = false,
        .include_docs = false,
    });

    try std.testing.expect(std.mem.indexOf(u8, text, "\"source\":\"inherited\"") == null);
    try std.testing.expect(std.mem.indexOf(u8, text, "Run leaf with structured metadata.") == null);
    try std.testing.expect(std.mem.indexOf(u8, text, "\"docs\":") == null);
}

test "minimal command tree emits valid schema" {
    const minimal = cli.Cmd{ .name = "empty" };
    const text = comptime cli.schema.json(minimal, .{});

    try expectContains(text, "\"root\":\"empty\"");
    try expectContains(text, "\"commands\":[{\"name\":\"empty\"");
    try expectContains(text, "\"flags\":[]");
    try expectContains(text, "\"positionals\":[]");
}

test "schema output is deterministic" {
    const a = comptime cli.schema.json(root, .{});
    const b = comptime cli.schema.json(root, .{});
    try std.testing.expectEqualStrings(a, b);
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}
