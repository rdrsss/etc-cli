const cli = @import("cli");

fn badHandler(_: u32) anyerror!void {}

comptime {
    _ = cli.handler(badHandler);
}
