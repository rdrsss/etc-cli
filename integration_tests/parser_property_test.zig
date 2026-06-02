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

// Generative property: parse is *total* over arbitrary token sequences — it
// must always return a result or a `Parse` error and never trip undefined
// behavior, and every error must populate `detail.kind` with a valid kind
// (so `errorKindName` resolves). Seeded for deterministic, reproducible runs.
test "parse is total over random token sequences" {
    const vocab = [_][]const u8{
        "run",      "--name",     "demo",      "--name=demo", "-ndemo",
        "--count",  "5",          "--count=9", "-c3",         "-v",
        "--verbose", "--no-verbose", "--",      "-5",          "--bogus",
        "alpha",    "beta",       "",          "-",           "x",
    };

    var prng = std.Random.DefaultPrng.init(0xC0FFEE_1234);
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 4000) : (iter += 1) {
        var argv_buf: [9][]const u8 = undefined;
        argv_buf[0] = "tool";
        const n = 1 + rand.uintLessThan(usize, argv_buf.len - 1);
        for (argv_buf[1..n]) |*slot| {
            slot.* = vocab[rand.uintLessThan(usize, vocab.len)];
        }
        const argv: []const []const u8 = argv_buf[0..n];

        var detail: cli.Detail = undefined;
        if (cli.parse(root, argv, &detail)) |_| {
            // Reaching here without UB/panic is the property.
        } else |_| {
            // The parser must have written a valid kind on the error path;
            // a non-empty name proves the enum value is in range.
            try std.testing.expect(cli.errorKindName(detail.kind).len > 0);
        }
    }
}
