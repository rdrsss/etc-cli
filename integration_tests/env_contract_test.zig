const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "env",
            .desc = "Exercise env fallback artifacts",
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

test "Flag.env declarations do not satisfy parse required flags" {
    var detail: cli.Detail = undefined;
    const result = cli.parse(root, &.{ "tool", "env" }, &detail);
    try std.testing.expectError(cli.Parse.MissingRequired, result);
    try std.testing.expectEqualStrings("--token", detail.flag.?);
}

test "parse argv and defaults keep normal precedence with Flag.env declarations" {
    var detail: cli.Detail = undefined;
    const result = try cli.parse(root, &.{ "tool", "env", "--token", "from-argv" }, &detail);
    const args = result.match.env;
    try std.testing.expectEqualStrings("from-argv", args.token);
    try std.testing.expectEqualStrings("plain", args.mode);
}

test "generated surfaces describe env as cli.run fallback" {
    const help = comptime cli.helpText(root, &.{"env"});
    try expectContains(help, "ENVIRONMENT:");
    try expectContains(help, "TOOL_TOKEN");
    try expectContains(help, "cli.run fallback for --token");
    try expectContains(help, "parse/dispatch env-unaware");

    const man = comptime cli.man.page(root, &.{"env"}, .{});
    try expectContains(man, ".SH ENVIRONMENT");
    try expectContains(man, "TOOL_TOKEN");
    try expectContains(man, "resolved command path");
    try expectContains(man, "do not read the environment");

    const schema = comptime cli.schema.json(root, .{});
    try expectContains(schema, "\"env\":\"TOOL_TOKEN\"");
    try expectContains(schema, "\"envBehavior\":\"cli-run-fallback\"");

    const bash_completion = comptime cli.completion.script(root, .bash);
    try expectNotContains(bash_completion, "TOOL_TOKEN");
    try expectNotContains(bash_completion, "TOOL_MODE");

    const zsh_completion = comptime cli.completion.script(root, .zsh);
    try expectNotContains(zsh_completion, "TOOL_TOKEN");
    try expectNotContains(zsh_completion, "TOOL_MODE");

    const fish_completion = comptime cli.completion.script(root, .fish);
    try expectNotContains(fish_completion, "TOOL_TOKEN");
    try expectNotContains(fish_completion, "TOOL_MODE");
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}

fn expectNotContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) == null);
}
