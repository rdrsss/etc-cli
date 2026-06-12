// SPDX-License-Identifier: MIT
const std = @import("std");
const cli = @import("cli");

const root = cli.Cmd{
    .name = "example",
    .desc = "Example etcli application",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .kind = .bool, .desc = "Enable verbose output", .default = .{ .bool = false } },
    },
    .doc = .{
        .homepage = "https://github.com/rdrsss/etcli",
        .license = "MIT",
        .version = "0.1.0",
    },
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run a named target",
            .flags = &.{
                .{ .long = "--name", .short = 'n', .kind = .string, .desc = "Target display name", .required = true },
                .{ .long = "--count", .short = 'c', .kind = .int, .desc = "Number of runs", .default = .{ .int = 1 } },
            },
            .positionals = &.{
                .{ .name = "target", .kind = .string, .desc = "Target identifier" },
            },
            .doc = .{
                .examples = &.{.{ .title = "Run alpha", .command = "example run --name demo alpha", .desc = "Runs alpha once." }},
                .exit_codes = &.{
                    .{ .code = 0, .desc = "Success." },
                    .{ .code = 2, .desc = "Invalid command-line input." },
                },
            },
            .run = cli.handler(handleRun),
        },
    },
};

comptime {
    cli.validate(root);
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const argv = try cli.argv(allocator, init.minimal.args);
    defer cli.freeArgv(allocator, argv);

    var stdout_buf: [4096]u8 = undefined;
    var stderr_buf: [4096]u8 = undefined;
    var stdout_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buf);
    var stderr_writer: std.Io.File.Writer = .init(.stderr(), init.io, &stderr_buf);

    const code = try cli.run(root, .{
        .argv = argv,
        .stdout = &stdout_writer.interface,
        .stderr = &stderr_writer.interface,
        .version = "0.1.0",
        .about = "Example application built with etcli.",
        // Colorize help only when stdout is a real terminal. The writer hides
        // the fd, so we detect TTY state here and hand it to the runner; `.auto`
        // also honors NO_COLOR when an env_lookup is provided.
        .color = .auto,
        .stdout_tty = std.Io.File.stdout().isTty(init.io) catch false,
    });
    std.process.exit(code);
}

fn handleRun(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"run"}, args_ptr);
    std.debug.print("run {s} as {s} count={d} verbose={}\n", .{
        args.target,
        args.name,
        args.count,
        args.verbose,
    });
}
