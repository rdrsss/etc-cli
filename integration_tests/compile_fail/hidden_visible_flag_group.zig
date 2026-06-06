const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--json", .kind = .bool },
        .{ .long = "--secret", .hidden = true, .kind = .bool },
    },
    .flag_groups = &.{
        .{ .name = "output", .mode = .required_one, .flags = &.{ "--json", "--secret" } },
    },
};

comptime {
    cli.validate(root);
}
