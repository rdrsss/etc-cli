const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "take",
            .flags = &.{
                .{ .long = "--count", .short = 'c', .kind = .int },
            },
            .positionals = &.{
                .{ .name = "value", .kind = .string, .required = true },
            },
        },
        .{
            .name = "legacy",
            .allow_unknown_flags = true,
            .flags = &.{
                .{ .long = "--local", .kind = .bool, .default = .{ .bool = false } },
            },
            .positionals = &.{
                .{ .name = "name", .kind = .string, .required = true },
            },
        },
        .{
            .name = "loose",
            .allow_extra_positionals = true,
            .positionals = &.{
                .{ .name = "name", .kind = .string, .required = true },
            },
        },
        .{
            .name = "rest",
            .positionals = &.{
                .{ .name = "name", .kind = .string, .required = true },
            },
            .rest_field = "tail",
        },
    },
};

comptime {
    cli.validate(root);
}

test "double dash terminates flag parsing" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "take", "--", "--literal" }, &detail);
    try std.testing.expectEqualStrings("--literal", result.match.take.value);
}

test "lone dash is parsed as a positional" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "take", "-" }, &detail);
    try std.testing.expectEqualStrings("-", result.match.take.value);
}

test "unknown flags require explicit opt-in" {
    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "take", "--coun", "value" }, &detail);
        try std.testing.expectError(cli.Parse.UnknownFlag, result);
        try std.testing.expectEqualStrings("--coun", detail.arg.?);
        try std.testing.expectEqualStrings("--count", detail.suggestion.?);
    }

    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "legacy", "--unknown", "ignored", "value" }, &detail);
        try std.testing.expectEqualStrings("value", result.match.legacy.name);
    }
}

test "unknown subcommands suggest nearby command names" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "legaacy" }, &detail);
    try std.testing.expectError(cli.Parse.UnknownSubcommand, result);
    try std.testing.expectEqualStrings("legaacy", detail.arg.?);
    try std.testing.expectEqualStrings("legacy", detail.suggestion.?);

    const structured = cli.structuredError(detail);
    try std.testing.expectEqualStrings("unknown_subcommand", structured.kind_name);
    try std.testing.expectEqualStrings("legacy", structured.suggestion.?);
}

test "unknown flag passthrough does not swallow a following known flag-shaped token" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "legacy", "--unknown", "--local", "value" }, &detail);
    try std.testing.expect(result.match.legacy.local);
    try std.testing.expectEqualStrings("value", result.match.legacy.name);
}

test "allow_extra_positionals ignores extras without changing declared fields" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "loose", "first", "second", "third" }, &detail);
    try std.testing.expectEqualStrings("first", result.match.loose.name);
}

test "rest_field captures extras in order and defaults to empty" {
    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "rest", "first", "second", "third" }, &detail);
        const args = result.match.rest;
        try std.testing.expectEqualStrings("first", args.name);
        try std.testing.expectEqual(@as(usize, 2), args.tail.len);
        try std.testing.expectEqualStrings("second", args.tail[0]);
        try std.testing.expectEqualStrings("third", args.tail[1]);
    }

    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "rest", "first" }, &detail);
        const args = result.match.rest;
        try std.testing.expectEqualStrings("first", args.name);
        try std.testing.expectEqual(@as(usize, 0), args.tail.len);
    }
}
