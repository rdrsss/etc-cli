const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "env",
            .desc = "Exercise env metadata",
            .flags = &.{
                .{ .long = "--token", .kind = .string, .required = true, .env = "TOOL_TOKEN" },
                .{ .long = "--mode", .kind = .string, .default = .{ .string = "plain" }, .env = "TOOL_MODE" },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "env metadata does not satisfy required flags" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "env" }, &detail);
    try std.testing.expectError(cli.Parse.MissingRequired, result);
    try std.testing.expectEqualStrings("--token", detail.flag.?);
}

test "argv and defaults keep normal precedence with env metadata present" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "env", "--token", "from-argv" }, &detail);
    const args = result.match.env;
    try std.testing.expectEqualStrings("from-argv", args.token);
    try std.testing.expectEqualStrings("plain", args.mode);
}

test "generated surfaces describe env as metadata only" {
    const help = comptime cli.helpText(root, &.{"env"});
    try expectNotContains(help, "TOOL_TOKEN");

    const man = comptime cli.man.page(root, &.{"env"}, .{});
    try expectContains(man, ".SH ENVIRONMENT");
    try expectContains(man, "TOOL_TOKEN");
    try expectContains(man, "The parser does not read environment variables.");

    const schema = comptime cli.schema.json(root, .{});
    try expectContains(schema, "\"env\":\"TOOL_TOKEN\"");
    try expectContains(schema, "\"envBehavior\":\"metadata-only\"");

    const completion = comptime cli.completion.script(root, .bash);
    try expectNotContains(completion, "TOOL_TOKEN");
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}

fn expectNotContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) == null);
}
