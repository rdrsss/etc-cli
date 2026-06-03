const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--mode", .kind = .choice },
    },
};

comptime {
    cli.validate(root);
}
