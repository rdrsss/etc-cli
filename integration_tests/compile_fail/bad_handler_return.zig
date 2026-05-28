const cli = @import("cli");

fn badHandler(_: *const anyopaque) void {}

comptime {
    _ = cli.handler(badHandler);
}
