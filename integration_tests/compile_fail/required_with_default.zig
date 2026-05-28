const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--name", .kind = .string, .required = true, .default = .{ .string = "value" } },
    },
};

comptime {
    cli.validate(root);
}
