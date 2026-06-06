const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{ .long = "--json", .aliases = &.{"--format"}, .short = 'j', .kind = .bool },
    },
    .flag_groups = &.{
        .{ .name = "output", .mode = .required_one, .flags = &.{"--format"} },
    },
};

comptime {
    cli.validate(root);
}
