const std = @import("std");
const cli = @import("cli");

const cli_root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .kind = .bool, .default = .{ .bool = false } },
    },
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run a package import smoke command",
            .flags = &.{
                .{ .long = "--name", .short = 'n', .kind = .string, .required = true },
                .{ .long = "--count", .short = 'c', .kind = .int, .default = .{ .int = 1 } },
            },
            .positionals = &.{
                .{ .name = "target", .kind = .string, .required = false },
            },
            .run = cli.handler(handleCliRun),
        },
    },
};

comptime {
    cli.validate(cli_root);
}

fn handleCliRun(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(cli_root, &.{"run"}, args_ptr);
    try std.testing.expectEqualStrings("consumer", args.name);
}

test "consumer can import cli module name and parse a command tree" {
    const argv: []const []const u8 = &.{ "tool", "--verbose", "run", "--name", "consumer", "--count", "3", "pkg" };
    var detail: cli.Detail = undefined;
    const result = try cli.parse(cli_root, argv, &detail);

    const args = result.match.run;
    try std.testing.expect(args.verbose);
    try std.testing.expectEqualStrings("consumer", args.name);
    try std.testing.expectEqual(@as(i64, 3), args.count);
    try std.testing.expect(args.target != null);
    try std.testing.expectEqualStrings("pkg", args.target.?);

    const help = comptime cli.helpText(cli_root, &.{"run"});
    try std.testing.expect(std.mem.indexOf(u8, help, "--name") != null);

    const completion = comptime cli.completion.script(cli_root, .bash);
    try std.testing.expect(std.mem.indexOf(u8, completion, "complete -F _tool tool") != null);
}
