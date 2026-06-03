const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--mode", .kind = .string, .choices = &.{ "a", "b" } },
    },
};

comptime {
    cli.validate(root);
}
