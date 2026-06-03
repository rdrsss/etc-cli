const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--mode", .kind = .choice, .choices = &.{ "a", "b" }, .default = .{ .choice = "c" } },
    },
};

comptime {
    cli.validate(root);
}
