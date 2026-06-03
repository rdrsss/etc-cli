//! Optional app-runner policy layered above parse/dispatch.

const std = @import("std");
const cmd_mod = @import("cmd.zig");
const err_mod = @import("error.zig");
const help_mod = @import("help.zig");
const parser = @import("parser.zig");

pub const ExitCodes = struct {
    success: u8 = 0,
    parse_error: u8 = 2,
    handler_error: u8 = 1,
};

pub const Options = struct {
    argv: []const []const u8,
    stdout: *std.Io.Writer,
    stderr: *std.Io.Writer,
    version: ?[]const u8 = null,
    about: ?[]const u8 = null,
    exit_codes: ExitCodes = .{},
    /// Optional hook invoked when a handler returns an error. It receives the
    /// error and the stderr writer and returns an exit code, or null to fall
    /// back to `exit_codes.handler_error`. When this hook is null the runner
    /// writes a concise `error: <name>` line to stderr. Use it to format
    /// handler errors, suppress the default line (when a handler already
    /// printed its own message), or map specific errors to exit codes.
    on_handler_error: ?*const fn (err: anyerror, stderr: *std.Io.Writer) anyerror!?u8 = null,
};

pub fn run(comptime root: cmd_mod.Cmd, options: Options) anyerror!u8 {
    if (try maybeBuiltin(root, options)) |code| return code;

    var detail: err_mod.Detail = undefined;
    const result = parser.parse(root, options.argv, &detail) catch {
        try err_mod.format(detail, options.stderr);
        try options.stderr.flush();
        return options.exit_codes.parse_error;
    };

    switch (result) {
        .help => |path| {
            const text = helpForAnyPath(root, path) orelse comptime help_mod.helpText(root, &.{});
            try options.stdout.print("{s}", .{text});
            try options.stdout.flush();
            return options.exit_codes.success;
        },
        .match => |u| {
            return invokeMatch(root, u, options);
        },
    }
}

fn maybeBuiltin(comptime root: cmd_mod.Cmd, options: Options) !?u8 {
    if (options.argv.len != 2) return null;
    const arg = options.argv[1];

    // `--version`/`--about` are conventional and always honored. The bare
    // words `version`/`about` are only intercepted when the tree does not
    // declare a real subcommand by that name, so a user's `version` command
    // is never silently shadowed by the runner.
    const want_version = std.mem.eql(u8, arg, "--version") or
        (std.mem.eql(u8, arg, "version") and comptime !hasSubcommand(root, "version"));
    if (want_version) {
        if (options.version) |version| {
            try options.stdout.print("{s}\n", .{version});
            try options.stdout.flush();
            return options.exit_codes.success;
        }
    }

    const want_about = std.mem.eql(u8, arg, "--about") or
        (std.mem.eql(u8, arg, "about") and comptime !hasSubcommand(root, "about"));
    if (want_about) {
        if (options.about) |about| {
            try options.stdout.print("{s}\n", .{about});
            try options.stdout.flush();
            return options.exit_codes.success;
        } else if (options.version) |version| {
            try options.stdout.print("{s} {s}\n", .{ root.name, version });
            try options.stdout.flush();
            return options.exit_codes.success;
        }
    }

    return null;
}

fn hasSubcommand(comptime root: cmd_mod.Cmd, comptime name: []const u8) bool {
    for (root.cmds) |c| {
        if (std.mem.eql(u8, c.name, name)) return true;
        for (c.aliases) |alias| {
            if (std.mem.eql(u8, alias, name)) return true;
        }
    }
    return false;
}

fn helpForAnyPath(comptime root: cmd_mod.Cmd, runtime_path: []const []const u8) ?[]const u8 {
    if (runtime_path.len == 0) return comptime help_mod.helpText(root, &.{});
    const nodes = comptime cmd_mod.allNodes(root);
    inline for (nodes) |node| {
        if (pathsEqual(node.path, runtime_path)) {
            return comptime help_mod.helpText(root, node.path);
        }
    }
    return null;
}

fn pathsEqual(a: []const []const u8, b: []const []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |aa, bb| {
        if (!std.mem.eql(u8, aa, bb)) return false;
    }
    return true;
}

fn invokeMatch(
    comptime root: cmd_mod.Cmd,
    result_union: parser.ResultUnion(root),
    options: Options,
) anyerror!u8 {
    const leaves = comptime cmd_mod.allLeaves(root);
    inline for (leaves) |leaf| {
        const tag_name = comptime pathToTag(leaf.path);
        if (std.mem.eql(u8, @tagName(std.meta.activeTag(result_union)), tag_name)) {
            // Warn (once) when the invoked command itself is deprecated. Flag-
            // level deprecation warnings are a separate follow-up; `dispatch`
            // (single-writer callback mode) does not emit these.
            if (comptime leaf.cmd.deprecated != null) {
                try emitDeprecation(options.stderr, leaf.cmd.name, leaf.cmd.deprecated.?);
            }
            if (leaf.cmd.run) |handler_ptr| {
                const handler_fn: cmd_mod.HandlerFn = @ptrCast(@alignCast(handler_ptr));
                const args = @field(result_union, tag_name);
                handler_fn(@ptrCast(&args)) catch |err| {
                    const code = if (options.on_handler_error) |hook|
                        try hook(err, options.stderr)
                    else blk: {
                        try options.stderr.print("error: {s}\n", .{@errorName(err)});
                        break :blk null;
                    };
                    try options.stderr.flush();
                    return code orelse options.exit_codes.handler_error;
                };
                try options.stdout.flush();
                return options.exit_codes.success;
            }

            const text = comptime help_mod.helpText(root, leaf.path);
            try options.stdout.print("{s}", .{text});
            try options.stdout.flush();
            return options.exit_codes.success;
        }
    }
    // The result union was built from one of `leaves`, so exactly one tag
    // matches above. Reaching here means the leaf/tag sets drifted apart.
    unreachable;
}

fn emitDeprecation(stderr: *std.Io.Writer, comptime name: []const u8, comptime d: anytype) std.Io.Writer.Error!void {
    try stderr.print("warning: '{s}' is deprecated", .{name});
    if (d.replacement) |replacement| try stderr.print("; use {s}", .{replacement});
    if (d.message.len > 0) try stderr.print("; {s}", .{d.message});
    try stderr.print("\n", .{});
    try stderr.flush();
}

fn pathToTag(comptime path: []const []const u8) []const u8 {
    comptime {
        if (path.len == 0) return "root";
        var joined: []const u8 = path[0];
        for (path[1..]) |seg| joined = joined ++ "_" ++ seg;
        var buf: [joined.len]u8 = undefined;
        for (joined, 0..) |c, i| buf[i] = if (c == '-') '_' else c;
        const final = buf;
        return &final;
    }
}
