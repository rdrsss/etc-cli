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
                        .{ .long = "--count", .short = 'c', .desc = "Count value", .kind = .int, .default = .{ .int = 1 } },
                    },
                    .positionals = &.{
                        .{ .name = "target", .desc = "Target name", .kind = .string },
                        .{ .name = "label", .desc = "Optional label", .kind = .string, .required = false },
                    },
                },
            },
        },
    },
};

comptime {
    cli.validate(root);
}

test "root man page renders conventional sections" {
    const text = comptime cli.man.page(root, &.{}, .{});

    try expectContains(text, ".TH \"tool\" \"1\"");
    try expectContains(text, ".SH NAME");
    try expectContains(text, "tool \\- Short root description");
    try expectContains(text, ".SH SYNOPSIS");
    try expectContains(text, ".SH DESCRIPTION");
    try expectContains(text, ".SH COMMANDS");
    try expectContains(text, ".B group");
    try expectContains(text, ".SH OPTIONS");
    try expectContains(text, "\\-\\-verbose");
}

test "subcommand man page includes inherited and local flags" {
    const text = comptime cli.man.page(root, &.{ "group", "run" }, .{});

    try expectContains(text, ".TH \"tool-group-run\" \"1\"");
    try expectContains(text, ".B tool group run");
    try expectContains(text, "Leaf long description for the command page.");
    try expectContains(text, "\\-\\-verbose");
    try expectContains(text, "\\-\\-mode");
    try expectContains(text, "\\-\\-name");
    try expectContains(text, "\\-\\-count, \\-c");
    try expectContains(text, ".SH ARGUMENTS");
    try expectContains(text, ".I target");
    try expectContains(text, ".I label");
}

test "options can set title and manual metadata" {
    const text = comptime cli.man.page(root, &.{ "group", "run" }, .{
        .title = "TOOL-RUN",
        .source = "etc-cli 1.0",
        .manual = "User Commands",
    });

    try expectContains(text, ".TH \"TOOL-RUN\" \"1\" \"\" \"etc-cli 1.0\" \"User Commands\"");
}

test "inherited flags can be omitted" {
    const text = comptime cli.man.page(root, &.{ "group", "run" }, .{
        .include_inherited_flags = false,
    });

    try std.testing.expect(std.mem.indexOf(u8, text, "\\-\\-verbose") == null);
    try std.testing.expect(std.mem.indexOf(u8, text, "\\-\\-mode") == null);
    try expectContains(text, "\\-\\-name");
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}
