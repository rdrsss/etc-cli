//! Shared command tree for the snapshot golden tests and the
//! `zig build snapshots-update` generator. Defining it once keeps the
//! regenerated artifacts and the asserted snapshots from drifting apart.

const cli = @import("cli");

fn completeHosts(prefix: []const u8) []const []const u8 {
    _ = prefix;
    return &.{"localhost"};
}

pub const root = cli.Cmd{
    .name = "tool",
    .desc = "Snapshot tool",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .desc = "Verbose output", .kind = .bool, .default = .{ .bool = false } },
        .{ .long = "--color", .kind = .choice, .choices = &.{ "auto", "always", "never" }, .default = .{ .choice = "auto" }, .desc = "When to colorize output" },
    },
    .flag_groups = &.{
        .{
            .name = "display",
            .mode = .required_one,
            .flags = &.{ "--verbose", "--color" },
            .desc = "Choose at least one display control.",
        },
    },
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run target",
            .flags = &.{
                .{ .long = "--name", .kind = .string, .desc = "Target name", .value_name = "NAME" },
                .{ .long = "--format", .short = 'f', .kind = .choice, .choices = &.{ "json", "text", "yaml" }, .default = .{ .choice = "text" }, .desc = "Output format" },
                .{ .long = "--rate", .kind = .float, .default = .{ .float = 1.5 }, .desc = "Sampling rate" },
                .{ .long = "--interval", .kind = .duration, .default = .{ .duration = 600 * 1_000_000_000 }, .desc = "Poll interval" },
                .{ .long = "--config", .kind = .path, .desc = "Config file path" },
                .{ .long = "--tag", .kind = .string, .list = true, .desc = "Repeatable tag" },
                .{ .long = "--host", .kind = .string, .completion = cli.Completion.dynamic(completeHosts), .desc = "Target host (dynamic)" },
            },
            .flag_groups = &.{
                .{
                    .name = "run-input",
                    .mode = .required_one,
                    .flags = &.{ "--name", "--host" },
                    .desc = "Choose at least one target input.",
                },
            },
            .positionals = &.{
                .{ .name = "target", .desc = "Target id", .kind = .string },
                .{ .name = "label", .desc = "Optional label", .kind = .string, .required = false, .default = .{ .string = "none" } },
            },
            .doc = .{
                .examples = &.{.{ .title = "Run", .command = "tool run --name demo alpha", .desc = "Runs alpha." }},
                .exit_codes = &.{.{ .code = 0, .desc = "Success." }},
                .see_also = &.{"tool(1)"},
                .homepage = "https://example.test/tool",
                .license = "MIT",
            },
        },
    },
};

pub const inherited_help_root = cli.Cmd{
    .name = "tool",
    .desc = "Inherited help snapshot tool",
    .flags = &.{
        .{ .long = "--global", .short = 'g', .kind = .bool, .default = .{ .bool = false }, .desc = "Global flag" },
    },
    .cmds = &.{
        .{
            .name = "group",
            .desc = "Parent command",
            .flags = &.{
                .{ .long = "--profile", .kind = .string, .desc = "Profile name" },
            },
            .flag_groups = &.{
                .{
                    .name = "group-scope",
                    .mode = .required_one,
                    .flags = &.{ "--global", "--profile" },
                    .desc = "Choose a global or profile scope.",
                },
            },
            .cmds = &.{
                .{
                    .name = "run",
                    .desc = "Leaf command",
                    .flags = &.{
                        .{ .long = "--count", .short = 'c', .kind = .int, .default = .{ .int = 1 }, .desc = "Run count" },
                    },
                    .flag_groups = &.{
                        .{
                            .name = "leaf-scope",
                            .mode = .required_exactly_one,
                            .flags = &.{ "--profile", "--count" },
                            .desc = "Choose exactly one leaf scope.",
                        },
                    },
                },
            },
        },
    },
};
