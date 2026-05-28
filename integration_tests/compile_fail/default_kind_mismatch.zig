const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--name", .kind = .string, .default = .{ .bool = false } },
    },
};

comptime {
    cli.validate(root);
}
