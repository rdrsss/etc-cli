const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .kind = .bool, .default = .{ .bool = false } },
        .{ .long = "--force", .short = 'f', .kind = .bool, .default = .{ .bool = false } },
    },
    .cmds = &.{
        .{
            .name = "run",
            .flags = &.{
                .{ .long = "--name", .short = 'n', .kind = .string, .required = true },
                .{ .long = "--count", .short = 'c', .kind = .int, .default = .{ .int = 1 } },
            },
            .positionals = &.{
                .{ .name = "target", .kind = .string },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "equivalent flag spellings produce equivalent args" {
    const cases = [_][]const []const u8{
        &.{ "tool", "run", "--name", "demo", "--count", "7", "--verbose", "alpha" },
        &.{ "tool", "run", "--name=demo", "--count=7", "--verbose=true", "alpha" },
        &.{ "tool", "-v", "run", "-ndemo", "-c7", "alpha" },
    };

    for (cases) |argv| {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, argv, &detail);
        const args = result.match.run;
        try std.testing.expect(args.verbose);
        try std.testing.expectEqualStrings("demo", args.name);
        try std.testing.expectEqual(@as(i64, 7), args.count);
        try std.testing.expectEqualStrings("alpha", args.target);
    }
}

test "bool negation and explicit false are equivalent" {
    const cases = [_][]const []const u8{
        &.{ "tool", "run", "--name", "demo", "--no-verbose", "alpha" },
        &.{ "tool", "run", "--name", "demo", "--verbose=false", "alpha" },
    };

    for (cases) |argv| {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, argv, &detail);
        try std.testing.expect(!result.match.run.verbose);
    }
}

test "duplicate scalar spellings are rejected regardless of syntax" {
    const cases = [_][]const []const u8{
        &.{ "tool", "run", "--name", "demo", "--name", "again", "alpha" },
        &.{ "tool", "run", "--name=demo", "-nagain", "alpha" },
    };

    for (cases) |argv| {
        var detail: cli.Detail = undefined;
        try std.testing.expectError(cli.Parse.DuplicateFlag, cli.parse(root, argv, &detail));
        try std.testing.expectEqualStrings("--name", detail.flag.?);
    }
}
