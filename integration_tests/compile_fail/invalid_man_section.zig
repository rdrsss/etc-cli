const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
};

comptime {
    _ = cli.man.page(root, &.{}, .{ .section = 2 });
}
