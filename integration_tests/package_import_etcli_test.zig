const std = @import("std");
const etcli = @import("etcli");

const PublicFlagGroup = etcli.FlagGroup;
const PublicFlagGroupMode = etcli.FlagGroupMode;

const root = etcli.Cmd{
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
            .run = etcli.handler(handleRun),
        },
    },
};

comptime {
    etcli.validate(root);
}

fn handleRun(args_ptr: *const anyopaque) anyerror!void {
    const args = etcli.castArgs(root, &.{"run"}, args_ptr);
    try std.testing.expectEqualStrings("consumer", args.name);
}

test "consumer can import etcli module name and parse a command tree" {
    const argv: []const []const u8 = &.{ "tool", "run", "--name", "consumer" };
    var detail: etcli.Detail = undefined;
    const result = try etcli.parse(root, argv, &detail);

    const args = result.match.run;
    try std.testing.expect(!args.verbose);
    try std.testing.expectEqualStrings("consumer", args.name);
    try std.testing.expectEqual(@as(i64, 1), args.count);
    try std.testing.expect(args.target == null);
    try std.testing.expectEqual(@as(usize, 1), root.cmds[0].flag_groups.len);
    try std.testing.expectEqual(PublicFlagGroupMode.required_one, root.cmds[0].flag_groups[0].mode);
    try std.testing.expectEqualStrings("--verbose", root.cmds[0].flag_groups[0].flags[0]);

    const help = comptime etcli.helpText(root, &.{"run"});
    try std.testing.expect(std.mem.indexOf(u8, help, "--count") != null);

    const completion = comptime etcli.completion.script(root, .zsh);
    try std.testing.expect(std.mem.indexOf(u8, completion, "#compdef tool") != null);

    const man = comptime etcli.man.page(root, &.{"run"}, .{});
    try std.testing.expect(std.mem.indexOf(u8, man, ".SH NAME") != null);

    const schema = comptime etcli.schema.json(root, .{});
    try std.testing.expect(std.mem.indexOf(u8, schema, "\"root\":\"tool\"") != null);
}
