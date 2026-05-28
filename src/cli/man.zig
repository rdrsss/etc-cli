//! Comptime man-page generator.
//!
//! `page(root, path, options)` returns portable `man(7)` roff text for one
//! command path. The string is built at comptime and can be printed or written
//! by downstream build/install code.

const std = @import("std");
const cmd_mod = @import("cmd.zig");
const flag_mod = @import("flag.zig");

pub const Options = struct {
    section: u8 = 1,
    title: ?[]const u8 = null,
    date: []const u8 = "",
    source: []const u8 = "",
    manual: []const u8 = "",
    include_inherited_flags: bool = true,
};

pub fn page(
    comptime root: cmd_mod.Cmd,
    comptime path: []const []const u8,
    comptime options: Options,
) []const u8 {
    @setEvalBranchQuota(4_000_000);
    if (options.section != 1) {
        @compileError("cli.man.page: only section 1 is supported for now");
    }
    const target = comptime cmd_mod.findCmd(root, path) orelse @compileError(
        "cli.man.page: no command at path",
    );
    return comptime renderPage(root, target, path, options);
}

pub fn pageName(comptime root: cmd_mod.Cmd, comptime path: []const []const u8) []const u8 {
    comptime {
        var out: []const u8 = root.name;
        for (path) |seg| out = out ++ "-" ++ seg;
        return out;
    }
}

fn renderPage(
    comptime root: cmd_mod.Cmd,
    comptime node: cmd_mod.Cmd,
    comptime path: []const []const u8,
    comptime options: Options,
) []const u8 {
    comptime {
        const name = pageName(root, path);
        const title = options.title orelse name;
        const command = commandPath(root, path);
        const desc = if (node.desc.len > 0) node.desc else "";
        const flags = flagsFor(root, node, path, options.include_inherited_flags);

        var out: []const u8 = "";
        out = out ++ ".TH \"" ++ roff(title) ++ "\" \"" ++ std.fmt.comptimePrint("{d}", .{options.section}) ++ "\"";
        out = out ++ " \"" ++ roff(options.date) ++ "\"";
        out = out ++ " \"" ++ roff(options.source) ++ "\"";
        out = out ++ " \"" ++ roff(options.manual) ++ "\"\n";

        out = out ++ ".SH NAME\n";
        out = out ++ roff(name);
        if (desc.len > 0) out = out ++ " \\- " ++ roff(desc);
        out = out ++ "\n";

        out = out ++ ".SH SYNOPSIS\n";
        out = out ++ ".B " ++ roff(command) ++ "\n";
        var synopsis_tail: []const u8 = "";
        if (flags.len > 0) synopsis_tail = synopsis_tail ++ " [OPTIONS]";
        if (node.cmds.len > 0) synopsis_tail = synopsis_tail ++ " <command>";
        for (node.positionals) |p| {
            synopsis_tail = synopsis_tail ++ " ";
            if (p.required) {
                synopsis_tail = synopsis_tail ++ "<" ++ roff(p.name) ++ ">";
            } else {
                synopsis_tail = synopsis_tail ++ "[" ++ roff(p.name) ++ "]";
            }
        }
        if (synopsis_tail.len > 0) out = out ++ ".RI \"" ++ synopsis_tail ++ "\"\n";

        const long_desc = if (node.long_desc.len > 0) node.long_desc else node.desc;
        if (long_desc.len > 0) {
            out = out ++ ".SH DESCRIPTION\n";
            out = out ++ ".PP\n" ++ roff(long_desc) ++ "\n";
        }

        if (node.cmds.len > 0) {
            out = out ++ ".SH COMMANDS\n";
            for (node.cmds) |child| {
                out = out ++ ".TP\n";
                out = out ++ ".B " ++ roff(child.name) ++ "\n";
                if (child.desc.len > 0) out = out ++ roff(child.desc) ++ "\n";
            }
        }

        if (flags.len > 0) {
            out = out ++ ".SH OPTIONS\n";
            for (flags) |f| out = out ++ renderFlag(f);
        }

        if (node.positionals.len > 0) {
            out = out ++ ".SH ARGUMENTS\n";
            for (node.positionals) |p| out = out ++ renderPositional(p);
        }

        return out;
    }
}

fn flagsFor(
    comptime root: cmd_mod.Cmd,
    comptime node: cmd_mod.Cmd,
    comptime path: []const []const u8,
    comptime include_inherited: bool,
) []const flag_mod.Flag {
    comptime {
        if (include_inherited) {
            return cmd_mod.collectInheritedFlags(root, path) ++ node.flags;
        }
        return node.flags;
    }
}

fn renderFlag(comptime f: flag_mod.Flag) []const u8 {
    comptime {
        var out: []const u8 = ".TP\n.B " ++ roffOption(f.long);
        if (f.short) |s| out = out ++ ", " ++ roffOption("-" ++ &[_]u8{s});
        out = out ++ "\n";
        out = out ++ @tagName(f.kind);
        if (f.required) out = out ++ ", required";
        if (f.default) |d| out = out ++ ", default=" ++ renderDefault(d);
        if (f.desc.len > 0) out = out ++ "\n" ++ roff(f.desc);
        out = out ++ "\n";
        return out;
    }
}

fn renderPositional(comptime p: flag_mod.Positional) []const u8 {
    comptime {
        var out: []const u8 = ".TP\n.I " ++ roff(p.name) ++ "\n";
        out = out ++ @tagName(p.kind);
        if (!p.required) out = out ++ ", optional";
        if (p.desc.len > 0) out = out ++ "\n" ++ roff(p.desc);
        out = out ++ "\n";
        return out;
    }
}

fn renderDefault(comptime d: flag_mod.Default) []const u8 {
    comptime {
        return switch (d) {
            .bool => |b| if (b) "true" else "false",
            .string => |s| "\"" ++ roff(s) ++ "\"",
            .int => |i| std.fmt.comptimePrint("{d}", .{i}),
        };
    }
}

fn commandPath(comptime root: cmd_mod.Cmd, comptime path: []const []const u8) []const u8 {
    comptime {
        var out: []const u8 = root.name;
        for (path) |seg| out = out ++ " " ++ seg;
        return out;
    }
}

fn roffOption(comptime text: []const u8) []const u8 {
    comptime {
        var out: []const u8 = "";
        for (text) |c| {
            if (c == '-') {
                out = out ++ "\\-";
            } else {
                out = out ++ roffChar(c);
            }
        }
        return out;
    }
}

fn roff(comptime text: []const u8) []const u8 {
    comptime {
        if (text.len == 0) return "";
        var out: []const u8 = "";
        if (text[0] == '.' or text[0] == '\'') out = out ++ "\\&";
        for (text) |c| out = out ++ roffChar(c);
        return out;
    }
}

fn roffChar(comptime c: u8) []const u8 {
    return switch (c) {
        '\\' => "\\e",
        else => &[_]u8{c},
    };
}

const test_root = cmd_mod.Cmd{
    .name = "tool",
    .desc = "Test tool",
    .flags = &.{
        .{ .long = "--verbose", .short = 'v', .desc = "Verbose output", .kind = .bool, .default = .{ .bool = false } },
    },
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run a target",
            .flags = &.{
                .{ .long = "--count", .desc = "Run count", .kind = .int, .default = .{ .int = 1 } },
            },
            .positionals = &.{
                .{ .name = "target", .desc = "Target name", .kind = .string },
            },
        },
    },
};

test "page renders root sections" {
    const text = comptime page(test_root, &.{}, .{});
    try std.testing.expect(std.mem.indexOf(u8, text, ".TH \"tool\" \"1\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, ".SH NAME") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "tool \\- Test tool") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, ".SH COMMANDS") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, ".SH OPTIONS") != null);
}

test "page renders inherited flags for leaf commands" {
    const text = comptime page(test_root, &.{"run"}, .{});
    try std.testing.expect(std.mem.indexOf(u8, text, "\\-\\-verbose") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "\\-\\-count") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, ".SH ARGUMENTS") != null);
}
