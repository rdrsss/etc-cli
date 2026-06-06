const std = @import("std");
const cli = @import("cli");

fn completeTargets(prefix: []const u8) []const []const u8 {
    _ = prefix;
    return &.{ "alpha", "beta" };
}

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
                        .{ .long = "--count", .short = 'c', .desc = "Count value", .kind = .int, .default = .{ .int = 1 }, .completion = cli.Completion.valueChoices(&.{ "1", "2" }) },
                    },
                    .flag_groups = &.{
                        .{
                            .name = "run-input",
                            .mode = .required_one,
                            .flags = &.{ "--mode", "--name" },
                            .desc = "Choose a mode or explicit name.",
                        },
                    },
                    .positionals = &.{
                        .{ .name = "target", .desc = "Target name", .kind = .string, .completion = cli.Completion.dynamic(completeTargets) },
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
                        .files = &.{"~/.config/tool/config.toml"},
                        .bugs = &.{"Report issues at https://example.test/tool/issues."},
                        .authors = &.{"Example Maintainers"},
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
    try expectNotContains(text, "\"commandTree\":");
    try expectContains(text, "\"path\":[]");
    try expectContains(text, "\"path\":[\"group\",\"run\"]");
    try expectContains(text, "\"command\":\"tool group run\"");
    try expectContains(text, "\"subcommands\":[\"group\"]");
    try expectContains(text, "\"long\":\"--verbose\"");
    try expectContains(text, "\"source\":\"inherited\"");
    try expectContains(text, "\"long\":\"--name\"");
    try expectContains(text, "\"valueName\":\"NAME\"");
    try expectContains(text, "\"env\":\"TOOL_NAME\"");
    try expectContains(text, "\"envBehavior\":\"cli-run-fallback\"");
    try expectContains(text, "\"flagGroups\":[{\"name\":\"run-input\",\"mode\":\"required_one\",\"flags\":[\"--mode\",\"--name\"],\"description\":\"Choose a mode or explicit name.\"}]");
    try expectContains(text, "\"positionals\":[{\"name\":\"target\"");
    try expectContains(text, "\"completion\":{\"kind\":\"values\",\"values\":[\"1\",\"2\"]}");
    try expectContains(text, "\"completion\":{\"kind\":\"dynamic\",\"values\":[]}");
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

test "schema command tree is opt-in and preserves flat commands" {
    const text = comptime cli.schema.json(root, .{ .include_command_tree = true });

    try expectContains(text, "\"schemaVersion\":1");
    try expectContains(text, "\"layout\":\"flat\"");
    try expectContains(text, "\"commands\":[");
    try expectContains(text, "\"path\":[\"group\",\"run\"]");
    try expectContains(text, "\"commandTree\":{\"name\":\"tool\"");
    try expectContains(text, "\"children\":[{\"name\":\"group\"");
    try expectContains(text, "\"children\":[{\"name\":\"run\"");

    var parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, text, .{});
    defer parsed.deinit();

    const schema_version = try jsonField(parsed.value, "schemaVersion");
    try std.testing.expect(schema_version == .integer);
    try std.testing.expect(schema_version.integer == 1);

    const commands = (try jsonField(parsed.value, "commands")).array.items;
    _ = try findCommandByPath(commands, &.{ "group", "run" });
}

test "schema command tree metadata matches flat leaf command" {
    const text = comptime cli.schema.json(root, .{ .include_command_tree = true });

    var parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, text, .{});
    defer parsed.deinit();

    const commands = (try jsonField(parsed.value, "commands")).array.items;
    const flat_run = try findCommandByPath(commands, &.{ "group", "run" });
    const tree_root = try jsonField(parsed.value, "commandTree");
    const tree_group = try findChildByName(tree_root, "group");
    const tree_run = try findChildByName(tree_group, "run");

    const parity_fields = [_][]const u8{
        "name",
        "aliases",
        "hidden",
        "deprecated",
        "path",
        "command",
        "summary",
        "description",
        "subcommands",
        "flags",
        "flagGroups",
        "positionals",
        "docs",
    };
    for (parity_fields) |key| {
        try expectJsonEqual(try jsonField(flat_run, key), try jsonField(tree_run, key));
    }
    try std.testing.expectEqual(@as(usize, 0), (try jsonField(tree_run, "children")).array.items.len);
}

test "schema command tree metadata honors flat rendering options" {
    const text = comptime cli.schema.json(root, .{
        .include_command_tree = true,
        .include_inherited_flags = false,
        .include_docs = false,
        .include_env_metadata = false,
    });

    var parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, text, .{});
    defer parsed.deinit();

    const commands = (try jsonField(parsed.value, "commands")).array.items;
    const flat_run = try findCommandByPath(commands, &.{ "group", "run" });
    const tree_root = try jsonField(parsed.value, "commandTree");
    const tree_run = try findChildByName(try findChildByName(tree_root, "group"), "run");

    try expectJsonEqual(try jsonField(flat_run, "flags"), try jsonField(tree_run, "flags"));
    try expectJsonEqual(try jsonField(flat_run, "flagGroups"), try jsonField(tree_run, "flagGroups"));
    try expectJsonEqual(try jsonField(flat_run, "positionals"), try jsonField(tree_run, "positionals"));
    try std.testing.expect((try jsonField(tree_run, "flags")).array.items.len == 2);
    try std.testing.expect((try jsonField(tree_run, "flagGroups")).array.items.len == 0);
    try expectNotContains(text, "\"source\":\"inherited\"");
    try expectNotContains(text, "\"docs\":");
    try expectNotContains(text, "\"envBehavior\":");
}

test "schema command tree output is deterministic" {
    const a = comptime cli.schema.json(root, .{ .include_command_tree = true });
    const b = comptime cli.schema.json(root, .{ .include_command_tree = true });
    try std.testing.expectEqualStrings(a, b);
}

test "schema command tree honors command visibility options" {
    const visibility_root = cli.Cmd{
        .name = "tool",
        .cmds = &.{
            .{ .name = "visible" },
            .{ .name = "secret", .hidden = true },
            .{ .name = "legacy", .deprecated = .{ .message = "deprecated" } },
        },
    };

    const default_text = comptime cli.schema.json(visibility_root, .{ .include_command_tree = true });
    try expectContains(default_text, "\"commandTree\":{\"name\":\"tool\"");
    try expectContains(default_text, "\"children\":[{\"name\":\"visible\"");
    try expectContains(default_text, "\"name\":\"legacy\"");
    try expectNotContains(default_text, "\"name\":\"secret\"");

    const hidden_text = comptime cli.schema.json(visibility_root, .{
        .include_command_tree = true,
        .include_hidden = true,
    });
    try expectContains(hidden_text, "\"name\":\"secret\"");

    const no_deprecated_text = comptime cli.schema.json(visibility_root, .{
        .include_command_tree = true,
        .include_deprecated = false,
    });
    try expectNotContains(no_deprecated_text, "\"name\":\"legacy\"");
}

test "schema flat and tree skip visible descendant under hidden parent" {
    const hidden_branch_root = cli.Cmd{
        .name = "tool",
        .cmds = &.{
            .{
                .name = "secret",
                .hidden = true,
                .cmds = &.{.{ .name = "run" }},
            },
        },
    };

    const default_text = comptime cli.schema.json(hidden_branch_root, .{ .include_command_tree = true });
    var default_parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, default_text, .{});
    defer default_parsed.deinit();

    const default_commands = (try jsonField(default_parsed.value, "commands")).array.items;
    try std.testing.expect(!(try hasCommandByPath(default_commands, &.{"secret"})));
    try std.testing.expect(!(try hasCommandByPath(default_commands, &.{ "secret", "run" })));
    try std.testing.expect(!(try hasChildByName(try jsonField(default_parsed.value, "commandTree"), "secret")));

    const include_hidden_text = comptime cli.schema.json(hidden_branch_root, .{
        .include_command_tree = true,
        .include_hidden = true,
    });
    var include_hidden_parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, include_hidden_text, .{});
    defer include_hidden_parsed.deinit();

    const include_hidden_commands = (try jsonField(include_hidden_parsed.value, "commands")).array.items;
    try std.testing.expect(try hasCommandByPath(include_hidden_commands, &.{"secret"}));
    try std.testing.expect(try hasCommandByPath(include_hidden_commands, &.{ "secret", "run" }));
    const hidden_tree_parent = try findChildByName(try jsonField(include_hidden_parsed.value, "commandTree"), "secret");
    _ = try findChildByName(hidden_tree_parent, "run");
}

test "schema flat and tree skip visible descendant under excluded deprecated parent" {
    const deprecated_branch_root = cli.Cmd{
        .name = "tool",
        .cmds = &.{
            .{
                .name = "legacy",
                .deprecated = .{ .message = "deprecated" },
                .cmds = &.{.{ .name = "run" }},
            },
        },
    };

    const excluded_text = comptime cli.schema.json(deprecated_branch_root, .{
        .include_command_tree = true,
        .include_deprecated = false,
    });
    var excluded_parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, excluded_text, .{});
    defer excluded_parsed.deinit();

    const excluded_commands = (try jsonField(excluded_parsed.value, "commands")).array.items;
    try std.testing.expect(!(try hasCommandByPath(excluded_commands, &.{"legacy"})));
    try std.testing.expect(!(try hasCommandByPath(excluded_commands, &.{ "legacy", "run" })));
    try std.testing.expect(!(try hasChildByName(try jsonField(excluded_parsed.value, "commandTree"), "legacy")));

    const include_deprecated_text = comptime cli.schema.json(deprecated_branch_root, .{
        .include_command_tree = true,
        .include_deprecated = true,
    });
    var include_deprecated_parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, include_deprecated_text, .{});
    defer include_deprecated_parsed.deinit();

    const include_deprecated_commands = (try jsonField(include_deprecated_parsed.value, "commands")).array.items;
    try std.testing.expect(try hasCommandByPath(include_deprecated_commands, &.{"legacy"}));
    try std.testing.expect(try hasCommandByPath(include_deprecated_commands, &.{ "legacy", "run" }));
    const deprecated_tree_parent = try findChildByName(try jsonField(include_deprecated_parsed.value, "commandTree"), "legacy");
    _ = try findChildByName(deprecated_tree_parent, "run");
}

test "schema can be written to a caller-owned writer" {
    var buf: [8192]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);
    try cli.schema.writeJson(root, .{}, &writer);
    try std.testing.expectEqualStrings(comptime cli.schema.json(root, .{}), writer.buffered());
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}

fn expectNotContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) == null);
}

fn jsonField(value: std.json.Value, key: []const u8) !std.json.Value {
    try std.testing.expect(value == .object);
    return value.object.get(key) orelse error.MissingJsonField;
}

fn findCommandByPath(commands: []const std.json.Value, path: []const []const u8) !std.json.Value {
    for (commands) |command| {
        if (try jsonStringArrayEquals(try jsonField(command, "path"), path)) return command;
    }
    return error.MissingJsonCommand;
}

fn hasCommandByPath(commands: []const std.json.Value, path: []const []const u8) !bool {
    for (commands) |command| {
        if (try jsonStringArrayEquals(try jsonField(command, "path"), path)) return true;
    }
    return false;
}

fn findChildByName(parent: std.json.Value, name: []const u8) !std.json.Value {
    const children = (try jsonField(parent, "children")).array.items;
    for (children) |child| {
        const child_name = try jsonField(child, "name");
        try std.testing.expect(child_name == .string);
        if (std.mem.eql(u8, child_name.string, name)) return child;
    }
    return error.MissingJsonChild;
}

fn hasChildByName(parent: std.json.Value, name: []const u8) !bool {
    const children = (try jsonField(parent, "children")).array.items;
    for (children) |child| {
        const child_name = try jsonField(child, "name");
        try std.testing.expect(child_name == .string);
        if (std.mem.eql(u8, child_name.string, name)) return true;
    }
    return false;
}

fn jsonStringArrayEquals(value: std.json.Value, expected: []const []const u8) !bool {
    try std.testing.expect(value == .array);
    if (value.array.items.len != expected.len) return false;
    for (value.array.items, expected) |actual, expected_item| {
        try std.testing.expect(actual == .string);
        if (!std.mem.eql(u8, actual.string, expected_item)) return false;
    }
    return true;
}

fn expectJsonEqual(a: std.json.Value, b: std.json.Value) !void {
    switch (a) {
        .null => try std.testing.expect(b == .null),
        .bool => |actual| {
            try std.testing.expect(b == .bool);
            try std.testing.expectEqual(actual, b.bool);
        },
        .integer => |actual| {
            try std.testing.expect(b == .integer);
            try std.testing.expectEqual(actual, b.integer);
        },
        .float => |actual| {
            try std.testing.expect(b == .float);
            try std.testing.expectEqual(actual, b.float);
        },
        .number_string => |actual| {
            try std.testing.expect(b == .number_string);
            try std.testing.expectEqualStrings(actual, b.number_string);
        },
        .string => |actual| {
            try std.testing.expect(b == .string);
            try std.testing.expectEqualStrings(actual, b.string);
        },
        .array => |actual| {
            try std.testing.expect(b == .array);
            try std.testing.expectEqual(actual.items.len, b.array.items.len);
            for (actual.items, b.array.items) |actual_item, expected_item| {
                try expectJsonEqual(actual_item, expected_item);
            }
        },
        .object => |actual| {
            try std.testing.expect(b == .object);
            try std.testing.expectEqual(actual.count(), b.object.count());
            var it = actual.iterator();
            while (it.next()) |entry| {
                const expected = b.object.get(entry.key_ptr.*) orelse return error.MissingJsonField;
                try expectJsonEqual(entry.value_ptr.*, expected);
            }
        },
    }
}
