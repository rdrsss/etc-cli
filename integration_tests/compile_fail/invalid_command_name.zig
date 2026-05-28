const cli = @import("cli");

const root = cli.Cmd{
    .name = "-tool",
};

comptime {
    cli.validate(root);
}
