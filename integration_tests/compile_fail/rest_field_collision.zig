const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--tail", .kind = .string },
    },
    .rest_field = "tail",
};

comptime {
    cli.validate(root);
}
