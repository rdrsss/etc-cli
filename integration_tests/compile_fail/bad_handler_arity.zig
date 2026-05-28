const cli = @import("cli");

fn badHandler(_: *const anyopaque, _: *const anyopaque) anyerror!void {}

comptime {
    _ = cli.handler(badHandler);
}
