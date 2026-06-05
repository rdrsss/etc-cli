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
        .{
            .name = "list",
            .flags = &.{
                .{ .long = "--item", .kind = .string, .list = true },
            },
        },
        .{
            .name = "parent",
            .cmds = &.{
                .{ .name = "leaf" },
            },
        },
        .{
            .name = "other",
            .cmds = &.{
                .{ .name = "child" },
            },
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

test "tail token cap returns a structured parse error" {
    var argv = repeatedPositionalsArgv("loose", 513);
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, argv[0..], &detail);
    try std.testing.expectError(cli.Parse.UnexpectedArgument, result);
    try std.testing.expectEqualStrings("too many tokens", detail.arg.?);

    const structured = cli.structuredError(detail);
    try std.testing.expectEqualStrings("unexpected_argument", structured.kind_name);
    try std.testing.expectEqualStrings("too many tokens", structured.arg.?);
}

test "rest_field cap returns TooManyPositionals at the capture boundary" {
    {
        var argv = restArgv(256);
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, argv[0..], &detail);
        try std.testing.expectEqual(@as(usize, 256), result.match.rest.tail.len);
    }

    {
        var argv = restArgv(257);
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, argv[0..], &detail);
        try std.testing.expectError(cli.Parse.TooManyPositionals, result);
        try std.testing.expectEqualStrings("extra", detail.arg.?);

        const structured = cli.structuredError(detail);
        try std.testing.expectEqualStrings("too_many_positionals", structured.kind_name);
        try std.testing.expectEqualStrings("extra", structured.arg.?);
    }
}

test "rest_field result slice is reused by the next rest parse" {
    var detail: cli.Detail = undefined;
    const first = try cli.parse(root, &.{ "tool", "rest", "head", "old-a", "old-b" }, &detail);
    const held_tail = first.match.rest.tail;
    try std.testing.expectEqual(@as(usize, 2), held_tail.len);
    try std.testing.expectEqualStrings("old-a", held_tail[0]);
    try std.testing.expectEqualStrings("old-b", held_tail[1]);

    _ = try cli.parse(root, &.{ "tool", "rest", "head", "new-a", "new-b" }, &detail);

    try std.testing.expectEqual(@as(usize, 2), held_tail.len);
    try std.testing.expectEqualStrings("new-a", held_tail[0]);
    try std.testing.expectEqualStrings("new-b", held_tail[1]);
}

test "list item cap returns a structured parse error at the item boundary" {
    {
        var argv = listItemsArgv(128);
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, argv[0..], &detail);
        try std.testing.expectEqual(@as(usize, 128), result.match.list.item.len);
    }

    {
        var argv = listItemsArgv(129);
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, argv[0..], &detail);
        try std.testing.expectError(cli.Parse.UnexpectedArgument, result);
        try std.testing.expectEqualStrings("--item", detail.flag.?);
        try std.testing.expectEqualStrings("value", detail.arg.?);

        const structured = cli.structuredError(detail);
        try std.testing.expectEqualStrings("unexpected_argument", structured.kind_name);
        try std.testing.expectEqualStrings("--item", structured.flag.?);
    }
}

test "list flag result slice is reused by the next list parse" {
    var detail: cli.Detail = undefined;
    const first = try cli.parse(root, &.{ "tool", "list", "--item", "old-a", "--item", "old-b" }, &detail);
    const held_items = first.match.list.item;
    try std.testing.expectEqual(@as(usize, 2), held_items.len);
    try std.testing.expectEqualStrings("old-a", held_items[0]);
    try std.testing.expectEqualStrings("old-b", held_items[1]);

    _ = try cli.parse(root, &.{ "tool", "list", "--item", "new-a", "--item", "new-b" }, &detail);

    try std.testing.expectEqual(@as(usize, 2), held_items.len);
    try std.testing.expectEqualStrings("new-a", held_items[0]);
    try std.testing.expectEqualStrings("new-b", held_items[1]);
}

test "help path result slice is reused by the next help parse" {
    const path = try nestedHelpPath("parent", "leaf");
    try std.testing.expectEqual(@as(usize, 2), path.len);
    try std.testing.expectEqualStrings("parent", path[0]);
    try std.testing.expectEqualStrings("leaf", path[1]);

    _ = try nestedHelpPath("other", "child");

    try std.testing.expectEqual(@as(usize, 2), path.len);
    try std.testing.expectEqualStrings("other", path[0]);
    try std.testing.expectEqualStrings("child", path[1]);
}

fn nestedHelpPath(comptime parent: []const u8, comptime leaf: []const u8) ![]const []const u8 {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", parent, leaf, "--help" }, &detail);
    return switch (result) {
        .help => |path| path,
        .match => error.ExpectedHelp,
    };
}

fn repeatedPositionalsArgv(comptime command: []const u8, comptime count: usize) [count + 2][]const u8 {
    var argv: [count + 2][]const u8 = undefined;
    argv[0] = "tool";
    argv[1] = command;
    for (0..count) |idx| {
        argv[idx + 2] = "extra";
    }
    return argv;
}

fn restArgv(comptime rest_count: usize) [rest_count + 3][]const u8 {
    var argv: [rest_count + 3][]const u8 = undefined;
    argv[0] = "tool";
    argv[1] = "rest";
    argv[2] = "head";
    for (0..rest_count) |idx| {
        argv[idx + 3] = "extra";
    }
    return argv;
}

fn listItemsArgv(comptime item_count: usize) [item_count * 2 + 2][]const u8 {
    var argv: [item_count * 2 + 2][]const u8 = undefined;
    argv[0] = "tool";
    argv[1] = "list";
    for (0..item_count) |idx| {
        argv[idx * 2 + 2] = "--item";
        argv[idx * 2 + 3] = "value";
    }
    return argv;
}
