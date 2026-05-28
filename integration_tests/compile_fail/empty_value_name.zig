const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--name", .kind = .string, .value_name = "" },
    },
};

comptime {
    cli.validate(root);
}
