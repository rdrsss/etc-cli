const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "run",
            .flags = &.{
                .{ .long = "--color", .short = 'c', .kind = .bool, .default = .{ .bool = true } },
                .{ .long = "--verbose", .short = 'v', .kind = .bool, .default = .{ .bool = false } },
                .{ .long = "--force", .short = 'f', .kind = .bool, .default = .{ .bool = false } },
                .{ .long = "--name", .short = 'n', .kind = .string, .required = true },
                .{ .long = "--count", .short = 'x', .kind = .int, .default = .{ .int = 1 } },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "explicit bool values and negation parse" {
    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "run", "--name", "demo", "--verbose=true", "--color=false" }, &detail);
        try std.testing.expect(result.match.run.verbose);
        try std.testing.expect(!result.match.run.color);
    }

    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "run", "--name", "demo", "--no-color" }, &detail);
        try std.testing.expect(!result.match.run.color);
    }
}

test "short bool bundles and attached short values parse" {
    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "run", "-vf", "-ndemo", "-x7" }, &detail);
        try std.testing.expect(result.match.run.verbose);
        try std.testing.expect(result.match.run.force);
        try std.testing.expectEqualStrings("demo", result.match.run.name);
        try std.testing.expectEqual(@as(i64, 7), result.match.run.count);
    }

    {
        var detail: cli.Detail = undefined;
        const result = try cli.parse(root, &.{ "tool", "run", "-cv", "--name", "demo" }, &detail);
        try std.testing.expect(result.match.run.color);
        try std.testing.expect(result.match.run.verbose);
    }
}

test "rejected parser expansion ambiguities fail predictably" {
    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "run", "--name", "demo", "--verbose=maybe" }, &detail);
        try std.testing.expectError(cli.Parse.InvalidValue, result);
        try std.testing.expectEqualStrings("--verbose", detail.flag.?);
        try std.testing.expectEqualStrings("maybe", detail.arg.?);
    }

    {
        var detail: cli.Detail = undefined;
        const result = cli.parse(root, &.{ "tool", "run", "-vn" }, &detail);
        try std.testing.expectError(cli.Parse.UnknownFlag, result);
        try std.testing.expectEqualStrings("-vn", detail.arg.?);
    }
}
