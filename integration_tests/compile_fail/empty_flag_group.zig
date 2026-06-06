const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flag_groups = &.{
        .{ .name = "output", .mode = .required_one, .flags = &.{} },
    },
};

comptime {
    cli.validate(root);
}
