const std = @import("std");
const cli = @import("cli");

var handler_called = false;
var handler_name: []const u8 = "";
var handler_count: i64 = 0;

const root = cli.Cmd{
    .name = "tool",
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run the dispatch smoke command",
            .flags = &.{
                .{ .long = "--name", .kind = .string, .required = true },
                .{ .long = "--count", .kind = .int, .default = .{ .int = 1 } },
            },
            .run = cli.handler(handleRun),
        },
        .{
            .name = "docs",
            .desc = "Render help when no handler is present",
        },
        .{
            .name = "fail",
            .desc = "Return a handler sentinel error",
            .run = cli.handler(handleFail),
        },
    },
};

comptime {
    cli.validate(root);
}

fn resetHandlerState() void {
    handler_called = false;
    handler_name = "";
    handler_count = 0;
}

fn handleRun(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"run"}, args_ptr);
    handler_called = true;
    handler_name = args.name;
    handler_count = args.count;
}

fn handleFail(args_ptr: *const anyopaque) anyerror!void {
    _ = args_ptr;
    return error.HandlerSentinel;
}

test "dispatch invokes a leaf handler with typed args" {
    resetHandlerState();
    var buf: [1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try cli.dispatch(root, &.{ "tool", "run", "--name=consumer", "--count", "4" }, &writer);

    try std.testing.expect(handler_called);
    try std.testing.expectEqualStrings("consumer", handler_name);
    try std.testing.expectEqual(@as(i64, 4), handler_count);
    try std.testing.expectEqual(@as(usize, 0), writer.buffered().len);
}

test "dispatch renders help for explicit help requests" {
    var buf: [2048]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try cli.dispatch(root, &.{ "tool", "run", "--help" }, &writer);

    const out = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, out, "Run the dispatch smoke command") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "--name") != null);
}

test "dispatch renders leaf help when no handler exists" {
    var buf: [2048]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    try cli.dispatch(root, &.{ "tool", "docs" }, &writer);

    const out = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, out, "Render help when no handler is present") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "USAGE:") != null);
}

test "dispatch formats parse errors before returning them" {
    var buf: [1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    const result = cli.dispatch(root, &.{ "tool", "run" }, &writer);
    try std.testing.expectError(cli.Parse.MissingRequired, result);

    const out = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, out, "required flag missing") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "--name") != null);
}

test "dispatch propagates handler errors" {
    var buf: [1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);

    const result = cli.dispatch(root, &.{ "tool", "fail" }, &writer);
    try std.testing.expectError(error.HandlerSentinel, result);
    try std.testing.expectEqual(@as(usize, 0), writer.buffered().len);
}
