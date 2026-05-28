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
                        .{ .long = "--name", .desc = "Name value", .kind = .string, .value_name = "NAME", .required = true, .env = "TOOL_NAME" },
                        .{ .long = "--count", .short = 'c', .desc = "Count value", .kind = .int, .default = .{ .int = 1 } },
                    },
                    .positionals = &.{
                        .{ .name = "target", .desc = "Target name", .kind = .string },
                        .{ .name = "label", .desc = "Optional label", .kind = .string, .required = false },
                    },
                    .doc = .{
                        .examples = &.{
                            .{ .title = "Run named target", .command = "tool group run --name demo target", .desc = "Runs the target named demo." },
                        },
                        .exit_codes = &.{
                            .{ .code = 0, .desc = "Command completed successfully." },
                            .{ .code = 2, .desc = "Command-line input was invalid." },
                        },
                        .notes = &.{
                            "Generated manual metadata does not change parser behavior.",
                        },
                        .see_also = &.{ "tool(1)", "tool-group(1)" },
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

test "example tree generates root and subcommand pages" {
    const root_page = comptime cli.man.page(root, &.{}, .{});
    const subcommand_page = comptime cli.man.page(root, &.{ "group", "run" }, .{});

    try expectContains(root_page, ".TH \"tool\" \"1\"");
    try expectContains(root_page, ".B group");
    try expectContains(subcommand_page, ".TH \"tool-group-run\" \"1\"");
    try expectContains(subcommand_page, ".B tool group run");
}

test "subcommand man page includes inherited and local flags" {
    const text = comptime cli.man.page(root, &.{ "group", "run" }, .{});

    try expectContains(text, ".TH \"tool-group-run\" \"1\"");
    try expectContains(text, ".B tool group run");
    try expectContains(text, "Leaf long description for the command page.");
    try expectContains(text, "\\-\\-verbose");
    try expectContains(text, "\\-\\-mode");
    try expectContains(text, "\\-\\-name NAME");
    try expectContains(text, "type: string, value: NAME, required");
    try expectContains(text, "\\-\\-count N, \\-c N");
    try expectContains(text, "type: int, value: N, default: 1");
    try expectContains(text, ".SH ENVIRONMENT");
    try expectContains(text, ".B TOOL_NAME");
    try expectContains(text, "Associated with \\-\\-name metadata. The parser does not read environment variables.");
    try expectContains(text, ".SH ARGUMENTS");
    try expectContains(text, ".I target");
    try expectContains(text, ".I label");
    try expectContains(text, "type: string, optional");
    try expectContains(text, ".SH EXAMPLES");
    try expectContains(text, ".SS Run named target");
    try expectContains(text, ".B tool group run --name demo target");
    try expectContains(text, ".SH EXIT STATUS");
    try expectContains(text, ".B 2");
    try expectContains(text, ".SH NOTES");
    try expectContains(text, ".SH SEE ALSO");
    try expectContains(text, "tool(1), tool-group(1)");
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
    try expectContains(text, "\\-\\-name NAME");
}

test "empty sections are omitted" {
    const empty = cli.Cmd{ .name = "empty" };
    const text = comptime cli.man.page(empty, &.{}, .{});

    try expectContains(text, ".SH NAME");
    try expectContains(text, ".SH SYNOPSIS");
    try std.testing.expect(std.mem.indexOf(u8, text, ".SH DESCRIPTION") == null);
    try std.testing.expect(std.mem.indexOf(u8, text, ".SH COMMANDS") == null);
    try std.testing.expect(std.mem.indexOf(u8, text, ".SH OPTIONS") == null);
    try std.testing.expect(std.mem.indexOf(u8, text, ".SH ARGUMENTS") == null);
}

test "roff-sensitive descriptions are escaped" {
    const escaping_root = cli.Cmd{
        .name = "escape",
        .desc = ".macro-looking\n'control line\npath \\ value",
        .flags = &.{
            .{ .long = "--dry-run", .desc = ".flag macro", .kind = .bool },
        },
    };
    const text = comptime cli.man.page(escaping_root, &.{}, .{ .title = "escape \"quoted\"" });

    try expectContains(text, "escape \\(dqquoted\\(dq");
    try expectContains(text, "\\&.macro-looking");
    try expectContains(text, "\n\\&'control line");
    try expectContains(text, "path \\e value");
    try expectContains(text, "\\-\\-dry\\-run");
    try expectContains(text, "\\&.flag macro");
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}
