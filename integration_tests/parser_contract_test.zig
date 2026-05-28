const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "act",
            .flags = &.{
                .{ .long = "--force", .short = 'f', .kind = .bool, .default = .{ .bool = false } },
                .{ .long = "--name", .short = 'n', .kind = .string, .required = true },
                .{ .long = "--count", .short = 'c', .kind = .int, .default = .{ .int = 1 } },
            },
            .positionals = &.{
                .{ .name = "amount", .kind = .int, .required = true },
            },
        },
        .{
            .name = "parent",
            .cmds = &.{
                .{ .name = "leaf" },
            },
        },
        .{
            .name = "env",
            .flags = &.{
                .{ .long = "--token", .kind = .string, .required = true, .env = "TOOL_TOKEN" },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "duplicate long and short flags return DuplicateFlag" {
    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "act", "--name", "n", "--force", "--force", "1" }, &detail);
        try std.testing.expectError(cli.Parse.DuplicateFlag, result);
        try std.testing.expectEqualStrings("--force", detail.flag.?);
    }

    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "act", "--name", "n", "-f", "-f", "1" }, &detail);
        try std.testing.expectError(cli.Parse.DuplicateFlag, result);
        try std.testing.expectEqualStrings("--force", detail.flag.?);
    }
}

test "non-bool flags require a value" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "act", "--name" }, &detail);
    try std.testing.expectError(cli.Parse.MissingValue, result);
    try std.testing.expectEqualStrings("--name", detail.flag.?);
}

test "invalid integer flag and positional values return InvalidValue" {
    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "act", "--name", "n", "--count", "many", "1" }, &detail);
        try std.testing.expectError(cli.Parse.InvalidValue, result);
        try std.testing.expectEqualStrings("--count", detail.flag.?);
        try std.testing.expectEqualStrings("many", detail.arg.?);
    }

    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "act", "--name", "n", "many" }, &detail);
        try std.testing.expectError(cli.Parse.InvalidValue, result);
        try std.testing.expectEqualStrings("amount", detail.positional.?);
        try std.testing.expectEqualStrings("many", detail.arg.?);
    }
}

test "required and extra positionals fail predictably" {
    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "act", "--name", "n" }, &detail);
        try std.testing.expectError(cli.Parse.MissingRequiredPositional, result);
        try std.testing.expectEqualStrings("amount", detail.positional.?);
    }

    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "act", "--name", "n", "1", "extra" }, &detail);
        try std.testing.expectError(cli.Parse.TooManyPositionals, result);
        try std.testing.expectEqualStrings("extra", detail.arg.?);
    }
}

test "unknown subcommand and bare parent command have stable outcomes" {
    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "missing" }, &detail);
        try std.testing.expectError(cli.Parse.UnknownSubcommand, result);
        try std.testing.expectEqualStrings("tool", detail.cmd_path.?);
    }

    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "parent" }, &detail);
        switch (result) {
            .help => |path| {
                try std.testing.expectEqual(@as(usize, 1), path.len);
                try std.testing.expectEqualStrings("parent", path[0]);
            },
            .match => return error.ExpectedHelp,
        }
    }
}

test "flag equals syntax is supported for string and int flags" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "act", "--name=n", "--count=7", "1" }, &detail);
    const args = result.match.act;
    try std.testing.expectEqualStrings("n", args.name);
    try std.testing.expectEqual(@as(i64, 7), args.count);
    try std.testing.expectEqual(@as(i64, 1), args.amount);
}

test "flag equals syntax shares duplicate and invalid-value handling" {
    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "act", "--name=n", "--name", "again", "1" }, &detail);
        try std.testing.expectError(cli.Parse.DuplicateFlag, result);
        try std.testing.expectEqualStrings("--name", detail.flag.?);
    }

    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "act", "--name=n", "--count=many", "1" }, &detail);
        try std.testing.expectError(cli.Parse.InvalidValue, result);
        try std.testing.expectEqualStrings("--count", detail.flag.?);
        try std.testing.expectEqualStrings("many", detail.arg.?);
    }
}

test "flag equals syntax supports bool flags" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "act", "--name=n", "--force=true", "1" }, &detail);
    const args = (try result).match.act;
    try std.testing.expect(args.force);
}

test "Flag.env metadata is reserved and does not satisfy required flags" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "env" }, &detail);
    try std.testing.expectError(cli.Parse.MissingRequired, result);
    try std.testing.expectEqualStrings("--token", detail.flag.?);
}
