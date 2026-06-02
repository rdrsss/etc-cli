//! Shared command tree for the snapshot golden tests and the
//! `zig build snapshots-update` generator. Defining it once keeps the
//! regenerated artifacts and the asserted snapshots from drifting apart.

const cli = @import("cli");

pub const root = cli.Cmd{
    .name = "tool",
    .desc = "Snapshot tool",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .desc = "Verbose output", .kind = .bool, .default = .{ .bool = false } },
    },
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run target",
            .flags = &.{
                .{ .long = "--name", .kind = .string, .desc = "Target name", .value_name = "NAME" },
            },
            .positionals = &.{
                .{ .name = "target", .desc = "Target id", .kind = .string },
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
