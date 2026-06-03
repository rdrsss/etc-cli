const std = @import("std");
const cli = @import("cli");

var handler_called = false;
var handler_name: []const u8 = "";

const root = cli.Cmd{
    .name = "tool",
    .desc = "Runner fixture",
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run handler",
            .flags = &.{
                .{ .long = "--name", .kind = .string, .required = true },
            },
            .run = cli.handler(handleRun),
        },
        .{
            .name = "fail",
            .desc = "Fail handler",
            .run = cli.handler(handleFail),
        },
        .{
            .name = "help-only",
            .desc = "No handler help",
        },
        .{
            .name = "legacy",
            .desc = "Legacy command",
            .deprecated = .{ .message = "use run instead", .replacement = "run" },
        },
    },
};

comptime {
    cli.validate(root);
}

fn reset() void {
    handler_called = false;
    handler_name = "";
}

fn handleRun(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"run"}, args_ptr);
    handler_called = true;
    handler_name = args.name;
}

fn handleFail(_: *const anyopaque) anyerror!void {
    return error.IntentionalFailure;
}

test "runner dispatches a valid command and returns success" {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "run", "--name", "consumer" },
        .stdout = &stdout,
        .stderr = &stderr,
    });

    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expect(handler_called);
    try std.testing.expectEqualStrings("consumer", handler_name);
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);
}

test "runner version and about write stdout and return success" {
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const version_code = try cli.run(root, .{
        .argv = &.{ "tool", "--version" },
        .stdout = &stdout,
        .stderr = &stderr,
        .version = "1.2.3",
    });
    try std.testing.expectEqual(@as(u8, 0), version_code);
    try std.testing.expectEqualStrings("1.2.3\n", stdout.buffered());

    stdout = std.Io.Writer.fixed(&stdout_buf);
    stderr = std.Io.Writer.fixed(&stderr_buf);
    const about_code = try cli.run(root, .{
        .argv = &.{ "tool", "about" },
        .stdout = &stdout,
        .stderr = &stderr,
        .version = "1.2.3",
        .about = "tool does work",
    });
    try std.testing.expectEqual(@as(u8, 0), about_code);
    try std.testing.expectEqualStrings("tool does work\n", stdout.buffered());
}

test "runner help and no-handler leaves write stdout with success" {
    var stdout_buf: [4096]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const help_code = try cli.run(root, .{
        .argv = &.{ "tool", "run", "--help" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 0), help_code);
    try expectContains(stdout.buffered(), "Run handler");
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);

    stdout = std.Io.Writer.fixed(&stdout_buf);
    stderr = std.Io.Writer.fixed(&stderr_buf);
    const no_handler_code = try cli.run(root, .{
        .argv = &.{ "tool", "help-only" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 0), no_handler_code);
    try expectContains(stdout.buffered(), "No handler help");
}

test "runner parse and handler errors use stderr and nonzero exit codes" {
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const parse_code = try cli.run(root, .{
        .argv = &.{ "tool", "run" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 2), parse_code);
    try expectContains(stderr.buffered(), "required flag missing");
    try std.testing.expectEqual(@as(usize, 0), stdout.buffered().len);

    stdout = std.Io.Writer.fixed(&stdout_buf);
    stderr = std.Io.Writer.fixed(&stderr_buf);
    const handler_code = try cli.run(root, .{
        .argv = &.{ "tool", "fail" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 1), handler_code);
    try expectContains(stderr.buffered(), "IntentionalFailure");
}

var hook_err_name: []const u8 = "";

fn onHandlerError(err: anyerror, stderr: *std.Io.Writer) anyerror!?u8 {
    hook_err_name = @errorName(err);
    try stderr.print("custom: {s}\n", .{@errorName(err)});
    return 42;
}

test "runner handler-error hook overrides message and exit code" {
    hook_err_name = "";
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "fail" },
        .stdout = &stdout,
        .stderr = &stderr,
        .on_handler_error = onHandlerError,
    });
    try std.testing.expectEqual(@as(u8, 42), code);
    try std.testing.expectEqualStrings("IntentionalFailure", hook_err_name);
    try expectContains(stderr.buffered(), "custom: IntentionalFailure");
}

test "runner warns on stderr when a deprecated command is invoked" {
    var stdout_buf: [4096]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "legacy" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 0), code);
    try expectContains(stderr.buffered(), "'legacy' is deprecated");
    try expectContains(stderr.buffered(), "use run");
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}
