const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--json", .kind = .bool, .required = true },
        .{ .long = "--yaml", .kind = .bool, .required = true },
    },
    .flag_groups = &.{
        .{ .name = "output", .mode = .required_exactly_one, .flags = &.{ "--json", "--yaml" } },
    },
};

comptime {
    cli.validate(root);
}
