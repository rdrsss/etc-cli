const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .desc = "Short root description",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .desc = "Verbose output", .kind = .bool, .default = .{ .bool = false } },
    },
    .cmds = &.{
        .{
            .name = "group",
            .desc = "Parent listing description",
            .long_desc = "Parent long description\nwith multiple lines.",
            .flags = &.{
                .{ .long = "--mode", .desc = "Mode selector", .kind = .string },
            },
            .cmds = &.{
                .{
                    .name = "run",
                    .desc = "Run leaf",
                    .long_desc = "Leaf long description for the command page.",
                    .flags = &.{
                        .{ .long = "--name", .desc = "Name value", .kind = .string, .required = true },
                    },
                },
            },
        },
        .{
            .name = "quote",
            .desc = "Say 'hi': then \"bye\" with $HOME and `pwd`",
            .flags = &.{
                .{ .long = "--path", .desc = "Path 'quoted': and \"double\" with $HOME and `pwd`", .kind = .string },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "parent and leaf help render the right descriptions and command structure" {
    const root_help = comptime cli.helpText(root, &.{});
    try std.testing.expect(std.mem.indexOf(u8, root_help, "group") != null);
    try std.testing.expect(std.mem.indexOf(u8, root_help, "Parent listing description") != null);

    const parent_help = comptime cli.helpText(root, &.{"group"});
    try std.testing.expect(std.mem.indexOf(u8, parent_help, "Parent long description") != null);
    try std.testing.expect(std.mem.indexOf(u8, parent_help, "run") != null);
    try std.testing.expect(std.mem.indexOf(u8, parent_help, "--mode") != null);

    const leaf_help = comptime cli.helpText(root, &.{ "group", "run" });
    try std.testing.expect(std.mem.indexOf(u8, leaf_help, "Leaf long description") != null);
    try std.testing.expect(std.mem.indexOf(u8, leaf_help, "--name") != null);
}

test "parent and leaf help include inherited flags in deterministic order" {
    const parent_help = comptime cli.helpText(root, &.{"group"});
    try std.testing.expect(std.mem.indexOf(u8, parent_help, "USAGE:\n  group [flags] <command>\n") != null);
    const parent_root_flag = std.mem.indexOf(u8, parent_help, "--verbose").?;
    const parent_local_flag = std.mem.indexOf(u8, parent_help, "--mode").?;
    try std.testing.expect(parent_root_flag < parent_local_flag);

    const leaf_help = comptime cli.helpText(root, &.{ "group", "run" });
    try std.testing.expect(std.mem.indexOf(u8, leaf_help, "USAGE:\n  group run [flags]\n") != null);
    const leaf_root_flag = std.mem.indexOf(u8, leaf_help, "--verbose").?;
    const leaf_parent_flag = std.mem.indexOf(u8, leaf_help, "--mode").?;
    const leaf_local_flag = std.mem.indexOf(u8, leaf_help, "--name").?;
    try std.testing.expect(leaf_root_flag < leaf_parent_flag);
    try std.testing.expect(leaf_parent_flag < leaf_local_flag);
}

test "help without visible flags keeps compact usage and omits flags section" {
    const hidden_only_root = cli.Cmd{
        .name = "tool",
        .flags = &.{
            .{ .long = "--hidden-root", .desc = "Hidden root flag", .kind = .bool, .hidden = true },
        },
        .cmds = &.{
            .{
                .name = "visible",
                .desc = "Visible command",
            },
            .{
                .name = "elsewhere",
                .desc = "Sibling with hidden flag",
                .flags = &.{
                    .{ .long = "--hidden-sibling", .desc = "Hidden sibling flag", .kind = .bool, .hidden = true },
                },
            },
        },
    };

    const help = comptime cli.helpText(hidden_only_root, &.{"visible"});
    try std.testing.expect(std.mem.indexOf(u8, help, "USAGE:\n  visible\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, help, "[flags]") == null);
    try std.testing.expect(std.mem.indexOf(u8, help, "FLAGS:") == null);
    try std.testing.expect(std.mem.indexOf(u8, help, "--hidden-root") == null);
    try std.testing.expect(std.mem.indexOf(u8, help, "--hidden-sibling") == null);
}

test "help supports compact width and writer output" {
    const compact = comptime cli.helpTextWithOptions(root, &.{}, .{ .width = 40 });
    try std.testing.expect(std.mem.indexOf(u8, compact, "  group\n      Parent listing description") != null);
    try std.testing.expect(std.mem.indexOf(u8, compact, "      Verbose output") != null);

    var buf: [2048]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);
    try cli.help.writeText(root, &.{}, .{}, &writer);
    try std.testing.expectEqualStrings(comptime cli.helpText(root, &.{}), writer.buffered());
}

test "bash and zsh completions include inherited and local flags" {
    const bash = comptime cli.completion.script(root, .bash);
    try std.testing.expect(std.mem.indexOf(u8, bash, "\"group run\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, bash, "--verbose") != null);
    try std.testing.expect(std.mem.indexOf(u8, bash, "--mode") != null);
    try std.testing.expect(std.mem.indexOf(u8, bash, "--name") != null);

    const zsh = comptime cli.completion.script(root, .zsh);
    try std.testing.expect(std.mem.indexOf(u8, zsh, "\"--verbose:Verbose output\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh, "\"--mode:Mode selector\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh, "\"--name:Name value\"") != null);
}

test "fish completion documents owned flags at each path" {
    const fish = comptime cli.completion.script(root, .fish);
    try std.testing.expect(std.mem.indexOf(u8, fish, "__fish_tool_path \"\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish, "__fish_tool_path \"group\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish, "__fish_tool_path \"group run\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish, "-l 'verbose' -s v") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish, "-l 'mode'") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish, "-l 'name'") != null);
}

test "completion escapes shell-sensitive descriptions" {
    const zsh = comptime cli.completion.script(root, .zsh);
    try std.testing.expect(std.mem.indexOf(u8, zsh, "\"quote:Say 'hi'\\: then \\\"bye\\\" with \\$HOME and \\`pwd\\`\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, zsh, "\"--path:Path 'quoted'\\: and \\\"double\\\" with \\$HOME and \\`pwd\\`\"") != null);

    const fish = comptime cli.completion.script(root, .fish);
    try std.testing.expect(std.mem.indexOf(u8, fish, "-a 'quote' -d 'Say \\'hi\\': then \"bye\" with $HOME and `pwd`'") != null);
    try std.testing.expect(std.mem.indexOf(u8, fish, "-l 'path' -d 'Path \\'quoted\\': and \"double\" with $HOME and `pwd`'") != null);
}
