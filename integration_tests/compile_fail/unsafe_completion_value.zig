const cli = @import("cli");

const root = cli.Cmd{
    .name = "tool",
    .flags = &.{
        .{
            .long = "--mode",
            .kind = .string,
            .completion = cli.Completion.valueChoices(&.{"$(touch /tmp/x)"}),
        },
    },
};

comptime {
    cli.validate(root);
}
