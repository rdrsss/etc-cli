const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .doc = .{
        .see_also = &.{""},
    },
};

comptime {
    cli.validate(root);
}
