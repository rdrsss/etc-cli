const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "run",
            .flags = &.{
                .{ .long = "--mode", .kind = .string, .completion = cli.Completion.valueChoices(&.{ "json", "text" }) },
                .{ .long = "--input", .kind = .string, .completion = cli.Completion.files },
                .{ .long = "--directory", .kind = .string, .completion = cli.Completion.directories },
            },
            .positionals = &.{
                .{ .name = "target", .completion = cli.Completion.valueChoices(&.{ "alpha", "beta" }) },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "static flag and positional value completions render for bash zsh and fish" {
    const bash = comptime cli.completion.script(root, .bash);
    try expectContains(bash, "--mode)");
    try expectContains(bash, "json text");
    try expectContains(bash, "compgen -f");
    try expectContains(bash, "compgen -d");
    try expectContains(bash, "alpha beta");

    const zsh = comptime cli.completion.script(root, .zsh);
    try expectContains(zsh, "--mode)");
    try expectContains(zsh, "_values 'values' \"json\" \"text\"");
    try expectContains(zsh, "_files -/");
    try expectContains(zsh, "\"alpha\" \"beta\"");

    const fish = comptime cli.completion.script(root, .fish);
    try expectContains(fish, "-l 'mode' -a 'json text'");
    try expectContains(fish, "-l 'input'");
    try expectContains(fish, "__fish_complete_directories");
    try expectContains(fish, "-a 'alpha beta'");
}

test "schema exposes completion metadata" {
    const schema = comptime cli.schema.json(root, .{});
    try expectContains(schema, "\"completion\":{\"kind\":\"values\",\"values\":[\"json\",\"text\"]}");
    try expectContains(schema, "\"completion\":{\"kind\":\"files\",\"values\":[]}");
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}
