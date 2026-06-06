const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--global", .short = 'g', .kind = .bool, .default = .{ .bool = false } },
    },
    .cmds = &.{
        .{
            .name = "optional",
            .flags = &.{
                .{ .long = "--json", .aliases = &.{"--as-json"}, .short = 'j', .kind = .bool, .default = .{ .bool = false } },
                .{ .long = "--yaml", .short = 'y', .kind = .bool, .default = .{ .bool = false } },
            },
            .flag_groups = &.{
                .{ .name = "output", .mode = .mutually_exclusive, .flags = &.{ "--json", "--yaml" } },
            },
        },
        .{
            .name = "required",
            .flags = &.{
                .{ .long = "--json", .kind = .bool, .default = .{ .bool = false } },
                .{ .long = "--yaml", .kind = .bool, .default = .{ .bool = false } },
            },
            .flag_groups = &.{
                .{ .name = "output", .mode = .required_one, .flags = &.{ "--json", "--yaml" } },
            },
        },
        .{
            .name = "exact",
            .flags = &.{
                .{ .long = "--json", .kind = .bool, .default = .{ .bool = false } },
                .{ .long = "--yaml", .kind = .bool, .default = .{ .bool = false } },
            },
            .flag_groups = &.{
                .{ .name = "output", .mode = .required_exactly_one, .flags = &.{ "--json", "--yaml" } },
            },
        },
        .{
            .name = "inherited",
            .flags = &.{
                .{ .long = "--local", .short = 'l', .kind = .bool, .default = .{ .bool = false } },
            },
            .flag_groups = &.{
                .{ .name = "scope", .mode = .required_exactly_one, .flags = &.{ "--global", "--local" } },
            },
        },
        .{
            .name = "defaults",
            .flags = &.{
                .{ .long = "--format", .kind = .choice, .choices = &.{ "json", "text" }, .default = .{ .choice = "text" } },
            },
            .flag_groups = &.{
                .{ .name = "format-source", .mode = .required_one, .flags = &.{"--format"} },
            },
        },
        .{
            .name = "forms",
            .flags = &.{
                .{ .long = "--name", .aliases = &.{"--title"}, .short = 'n', .kind = .string },
                .{ .long = "--count", .short = 'x', .kind = .int },
            },
            .flag_groups = &.{
                .{ .name = "input", .mode = .mutually_exclusive, .flags = &.{ "--name", "--count" } },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "flag group accepts a valid one-of selection" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "optional", "--json" }, &detail);
    try std.testing.expect(result.match.optional.json);
    try std.testing.expect(!result.match.optional.yaml);
}

test "valid flag group selection renders generated surfaces" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "optional", "--json" }, &detail);
    try std.testing.expect(result.match.optional.json);

    const help = comptime cli.helpText(root, &.{"optional"});
    try expectContains(help, "FLAG GROUPS:");
    try expectContains(help, "output");
    try expectContains(help, "mutually exclusive: --json, --yaml");

    const man = comptime cli.man.page(root, &.{"optional"}, .{});
    try expectContains(man, ".SH FLAG GROUPS");
    try expectContains(man, "mutually exclusive: \\-\\-json, \\-\\-yaml");

    const schema = comptime cli.schema.json(root, .{});
    try expectContains(schema, "\"flagGroups\":[{\"name\":\"output\",\"mode\":\"mutually_exclusive\",\"flags\":[\"--json\",\"--yaml\"],\"description\":\"\"}]");
}

test "optional mutually exclusive group permits no selection" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "optional" }, &detail);
    try std.testing.expect(!result.match.optional.json);
    try std.testing.expect(!result.match.optional.yaml);
}

test "mutually exclusive group rejects multiple members with structured detail" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "optional", "--json", "--yaml" }, &detail);
    try std.testing.expectError(cli.Parse.FlagGroupViolation, result);
    try expectGroupViolation(detail, "output", .mutually_exclusive, "tool optional", &.{ "--json", "--yaml" });
}

test "required-one group rejects missing selection" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "required" }, &detail);
    try std.testing.expectError(cli.Parse.FlagGroupViolation, result);
    try expectGroupViolation(detail, "output", .required_one, "tool required", &.{ "--json", "--yaml" });
}

test "required-exactly-one group rejects missing selection" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "exact" }, &detail);
    try std.testing.expectError(cli.Parse.FlagGroupViolation, result);
    try expectGroupViolation(detail, "output", .required_exactly_one, "tool exact", &.{ "--json", "--yaml" });
}

test "inherited flags participate in leaf command groups" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "-g", "inherited" }, &detail);
    try std.testing.expect(result.match.inherited.global);
    try std.testing.expect(!result.match.inherited.local);

    const too_many = cli.parse(root, &.{ "tool", "-g", "inherited", "--local" }, &detail);
    try std.testing.expectError(cli.Parse.FlagGroupViolation, too_many);
    try expectGroupViolation(detail, "scope", .required_exactly_one, "tool inherited", &.{ "--global", "--local" });
}

test "flag defaults do not count as group presence" {
    var detail: cli.Detail = undefined;
    const missing = cli.parse(root, &.{ "tool", "defaults" }, &detail);
    try std.testing.expectError(cli.Parse.FlagGroupViolation, missing);
    try expectGroupViolation(detail, "format-source", .required_one, "tool defaults", &.{"--format"});

    const present = try cli.parse(root, &.{ "tool", "defaults", "--format", "json" }, &detail);
    try std.testing.expectEqualStrings("json", present.match.defaults.format);
}

test "aliases equals forms and attached short values map to canonical group members" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "forms", "--title=demo", "-x7" }, &detail);
    try std.testing.expectError(cli.Parse.FlagGroupViolation, result);
    try expectGroupViolation(detail, "input", .mutually_exclusive, "tool forms", &.{ "--name", "--count" });
}

fn expectGroupViolation(
    detail: cli.Detail,
    expected_group: []const u8,
    expected_mode: cli.FlagGroupMode,
    expected_path: []const u8,
    expected_flags: []const []const u8,
) !void {
    try std.testing.expectEqual(cli.Parse.FlagGroupViolation, detail.kind);
    try std.testing.expectEqualStrings(expected_group, detail.group.?);
    try std.testing.expectEqual(expected_mode, detail.group_mode.?);
    try std.testing.expectEqualStrings(expected_path, detail.cmd_path.?);
    try std.testing.expectEqual(expected_flags.len, detail.group_flags.len);
    for (expected_flags, 0..) |expected, idx| {
        try std.testing.expectEqualStrings(expected, detail.group_flags[idx]);
    }

    const structured = cli.structuredError(detail);
    try std.testing.expectEqualStrings("flag_group_violation", structured.kind_name);
    try std.testing.expectEqualStrings(expected_group, structured.group.?);
    try std.testing.expectEqual(expected_mode, structured.group_mode.?);
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}
