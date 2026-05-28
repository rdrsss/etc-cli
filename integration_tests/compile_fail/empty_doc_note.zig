const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .doc = .{
        .notes = &.{""},
    },
};

comptime {
    cli.validate(root);
}
