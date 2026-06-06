const std = @import("std");
const etc_cli = @import("etc_cli");

const PublicFlagGroup = etc_cli.FlagGroup;
const PublicFlagGroupMode = etc_cli.FlagGroupMode;

const root = etc_cli.Cmd{
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
            .flag_groups = &.{
                PublicFlagGroup{
                    .name = "run-selection",
                    .mode = PublicFlagGroupMode.required_one,
                    .flags = &.{ "--verbose", "--name" },
                    .desc = "Select a run input.",
                },
            },
            .positionals = &.{
                .{ .name = "target", .kind = .string, .required = false },
            },
            .run = etc_cli.handler(handleRun),
        },
    },
};

comptime {
    etc_cli.validate(root);
}

fn handleRun(args_ptr: *const anyopaque) anyerror!void {
    const args = etc_cli.castArgs(root, &.{"run"}, args_ptr);
    try std.testing.expectEqualStrings("consumer", args.name);
}

test "consumer can import etc_cli module name and parse a command tree" {
    const argv: []const []const u8 = &.{ "tool", "run", "--name", "consumer" };
    var detail: etc_cli.Detail = undefined;
    const result = try etc_cli.parse(root, argv, &detail);

    const args = result.match.run;
    try std.testing.expect(!args.verbose);
    try std.testing.expectEqualStrings("consumer", args.name);
    try std.testing.expectEqual(@as(i64, 1), args.count);
    try std.testing.expect(args.target == null);
    try std.testing.expectEqual(@as(usize, 1), root.cmds[0].flag_groups.len);
    try std.testing.expectEqual(PublicFlagGroupMode.required_one, root.cmds[0].flag_groups[0].mode);
    try std.testing.expectEqualStrings("--verbose", root.cmds[0].flag_groups[0].flags[0]);

    const help = comptime etc_cli.helpText(root, &.{"run"});
    try std.testing.expect(std.mem.indexOf(u8, help, "--count") != null);

    const completion = comptime etc_cli.completion.script(root, .zsh);
    try std.testing.expect(std.mem.indexOf(u8, completion, "#compdef tool") != null);

    const man = comptime etc_cli.man.page(root, &.{"run"}, .{});
    try std.testing.expect(std.mem.indexOf(u8, man, ".SH NAME") != null);

    const schema = comptime etc_cli.schema.json(root, .{});
    try std.testing.expect(std.mem.indexOf(u8, schema, "\"root\":\"tool\"") != null);
}
