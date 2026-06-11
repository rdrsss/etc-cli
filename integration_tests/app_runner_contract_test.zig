const std = @import("std");
const cli = @import("cli");

var handler_called = false;
var handler_name: []const u8 = "";
var handler_token: []const u8 = "";
var handler_profile: []const u8 = "";
var handler_mode: []const u8 = "";
var handler_enabled = false;
var handler_color = false;
var handler_label: []const u8 = "";
var handler_count: i64 = 0;
var handler_rate: f64 = 0;
var handler_timeout: u64 = 0;
var handler_config: []const u8 = "";
var handler_format: []const u8 = "";
var handler_tags: []const []const u8 = &.{};
var handler_levels: []const []const u8 = &.{};

const root = cli.Cmd{
    .name = "tool",
    .desc = "Runner fixture",
    .flags = &.{
        .{ .long = "--token", .aliases = &.{"--auth"}, .short = 't', .kind = .string, .env = "TOOL_TOKEN" },
    },
    .cmds = &.{
        .{
            .name = "run",
            .desc = "Run handler",
            .flags = &.{
                .{ .long = "--name", .kind = .string, .required = true },
                .{ .long = "--old-name", .kind = .string, .deprecated = .{ .replacement = "--name", .message = "renamed" } },
            },
            .run = cli.handler(handleRun),
        },
        .{
            .name = "env-leaf",
            .desc = "Leaf env handler",
            .flags = &.{
                .{ .long = "--profile", .kind = .string, .env = "TOOL_PROFILE" },
            },
            .flag_groups = &.{
                .{ .name = "profile-source", .mode = .required_one, .flags = &.{"--profile"} },
            },
            .run = cli.handler(handleEnvLeaf),
        },
        .{
            .name = "other-env",
            .desc = "Sibling env handler",
            .flags = &.{
                .{ .long = "--region", .kind = .string, .env = "TOOL_REGION" },
            },
            .run = cli.handler(handleOtherEnv),
        },
        .{
            .name = "default-env",
            .desc = "Default env handler",
            .flags = &.{
                .{ .long = "--mode", .kind = .string, .default = .{ .string = "plain" }, .env = "TOOL_MODE" },
            },
            .run = cli.handler(handleDefaultEnv),
        },
        .{
            .name = "required-env",
            .desc = "Required env handler",
            .flags = &.{
                .{ .long = "--secret", .kind = .string, .required = true, .env = "TOOL_SECRET" },
            },
            .run = cli.handler(handleRequiredEnv),
        },
        .{
            .name = "env-kinds",
            .desc = "Env kind handler",
            .flags = &.{
                .{ .long = "--enabled", .kind = .bool, .default = .{ .bool = false }, .env = "TOOL_ENABLED" },
                .{ .long = "--color", .kind = .bool, .default = .{ .bool = true }, .env = "TOOL_COLOR" },
                .{ .long = "--label", .kind = .string, .env = "TOOL_LABEL" },
                .{ .long = "--count", .kind = .int, .env = "TOOL_COUNT" },
                .{ .long = "--rate", .kind = .float, .env = "TOOL_RATE" },
                .{ .long = "--timeout", .kind = .duration, .env = "TOOL_TIMEOUT" },
                .{ .long = "--config", .kind = .path, .env = "TOOL_CONFIG" },
                .{ .long = "--format", .kind = .choice, .choices = &.{ "json", "text" }, .env = "TOOL_FORMAT" },
                .{ .long = "--tag", .kind = .string, .list = true, .env = "TOOL_TAG" },
                .{ .long = "--level", .kind = .choice, .choices = &.{ "low", "high" }, .list = true, .env = "TOOL_LEVEL" },
            },
            .run = cli.handler(handleEnvKinds),
        },
        .{
            .name = "fail",
            .desc = "Fail handler",
            .run = cli.handler(handleFail),
        },
        .{
            .name = "help-only",
            .desc = "No handler help",
        },
        .{
            .name = "legacy",
            .desc = "Legacy command",
            .deprecated = .{ .message = "use run instead", .replacement = "run" },
        },
    },
};

comptime {
    cli.validate(root);
}

fn reset() void {
    handler_called = false;
    handler_name = "";
    handler_token = "";
    handler_profile = "";
    handler_mode = "";
    handler_enabled = false;
    handler_color = false;
    handler_label = "";
    handler_count = 0;
    handler_rate = 0;
    handler_timeout = 0;
    handler_config = "";
    handler_format = "";
    handler_tags = &.{};
    handler_levels = &.{};
}

fn handleRun(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"run"}, args_ptr);
    handler_called = true;
    handler_name = args.name;
    handler_token = args.token orelse "";
}

fn fakeEnv(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "TOOL_TOKEN")) return "envtoken";
    if (std.mem.eql(u8, name, "TOOL_PROFILE")) return "envprofile";
    if (std.mem.eql(u8, name, "TOOL_REGION")) return "envregion";
    if (std.mem.eql(u8, name, "TOOL_MODE")) return "envmode";
    return null;
}

fn envKinds(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "TOOL_ENABLED")) return "true";
    if (std.mem.eql(u8, name, "TOOL_COLOR")) return "false";
    if (std.mem.eql(u8, name, "TOOL_LABEL")) return "env-label";
    if (std.mem.eql(u8, name, "TOOL_COUNT")) return "7";
    if (std.mem.eql(u8, name, "TOOL_RATE")) return "2.5";
    if (std.mem.eql(u8, name, "TOOL_TIMEOUT")) return "10m";
    if (std.mem.eql(u8, name, "TOOL_CONFIG")) return "/tmp/tool.conf";
    if (std.mem.eql(u8, name, "TOOL_FORMAT")) return "json";
    if (std.mem.eql(u8, name, "TOOL_TAG")) return "alpha,beta";
    if (std.mem.eql(u8, name, "TOOL_LEVEL")) return "high";
    return null;
}

fn missingEnv(_: []const u8) ?[]const u8 {
    return null;
}

fn expectRunToken(
    argv: []const []const u8,
    expected: []const u8,
    env_lookup: ?*const fn (name: []const u8) ?[]const u8,
) !void {
    var so: [1024]u8 = undefined;
    var se: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&so);
    var stderr = std.Io.Writer.fixed(&se);

    handler_token = "";
    const code = try cli.run(root, .{ .argv = argv, .stdout = &stdout, .stderr = &stderr, .env_lookup = env_lookup });
    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expectEqualStrings(expected, handler_token);
}

test "runner fills a global flag from env when absent and leaves it empty when env is absent" {
    try expectRunToken(&.{ "tool", "run", "--name", "x" }, "envtoken", fakeEnv);
    try expectRunToken(&.{ "tool", "run", "--name", "x" }, "", missingEnv);
}

test "runner lets every env-backed global flag spelling win over env" {
    const Case = struct {
        argv: []const []const u8,
        expected: []const u8,
    };
    const cases = [_]Case{
        .{ .argv = &.{ "tool", "run", "--name", "x", "--token", "cli-long" }, .expected = "cli-long" },
        .{ .argv = &.{ "tool", "run", "--name", "x", "--token=cli-equals" }, .expected = "cli-equals" },
        .{ .argv = &.{ "tool", "run", "--name", "x", "--auth", "cli-alias" }, .expected = "cli-alias" },
        .{ .argv = &.{ "tool", "run", "--name", "x", "--auth=cli-alias-equals" }, .expected = "cli-alias-equals" },
        .{ .argv = &.{ "tool", "run", "--name", "x", "-t", "cli-short" }, .expected = "cli-short" },
        .{ .argv = &.{ "tool", "run", "--name", "x", "-tcli-attached" }, .expected = "cli-attached" },
    };

    for (cases) |c| {
        try expectRunToken(c.argv, c.expected, fakeEnv);
    }
}

test "runner does not treat another flag value as argv presence for env fallback" {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "run", "--name", "--token" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = fakeEnv,
    });

    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expectEqualStrings("--token", handler_name);
    try std.testing.expectEqualStrings("envtoken", handler_token);
}

fn handleEnvLeaf(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"env-leaf"}, args_ptr);
    handler_called = true;
    handler_profile = args.profile orelse "";
}

fn handleOtherEnv(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"other-env"}, args_ptr);
    handler_called = true;
    handler_profile = args.region orelse "";
}

test "runner resolves leaf path before collecting env-backed flag candidates" {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "env-leaf" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = fakeEnv,
    });

    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expect(handler_called);
    try std.testing.expectEqualStrings("envprofile", handler_profile);
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);
}

fn handleDefaultEnv(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"default-env"}, args_ptr);
    handler_called = true;
    handler_mode = args.mode;
}

fn handleRequiredEnv(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"required-env"}, args_ptr);
    handler_called = true;
    handler_mode = args.secret;
}

test "runner env fallback beats declared default and missing env falls through to default" {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const env_code = try cli.run(root, .{
        .argv = &.{ "tool", "default-env" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = fakeEnv,
    });
    try std.testing.expectEqual(@as(u8, 0), env_code);
    try std.testing.expectEqualStrings("envmode", handler_mode);

    reset();
    stdout = std.Io.Writer.fixed(&stdout_buf);
    stderr = std.Io.Writer.fixed(&stderr_buf);
    const default_code = try cli.run(root, .{
        .argv = &.{ "tool", "default-env" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = missingEnv,
    });
    try std.testing.expectEqual(@as(u8, 0), default_code);
    try std.testing.expectEqualStrings("plain", handler_mode);
}

test "runner missing env leaves required flag and group errors intact" {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const required_code = try cli.run(root, .{
        .argv = &.{ "tool", "required-env" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = missingEnv,
    });
    try std.testing.expectEqual(@as(u8, 2), required_code);
    try std.testing.expect(!handler_called);
    try std.testing.expect(std.mem.indexOf(u8, stderr.buffered(), "--secret") != null);

    reset();
    stdout = std.Io.Writer.fixed(&stdout_buf);
    stderr = std.Io.Writer.fixed(&stderr_buf);
    const group_code = try cli.run(root, .{
        .argv = &.{ "tool", "env-leaf" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = missingEnv,
    });
    try std.testing.expectEqual(@as(u8, 2), group_code);
    try std.testing.expect(!handler_called);
    try std.testing.expect(std.mem.indexOf(u8, stderr.buffered(), "profile-source") != null);
}

test "parse remains env-unaware for leaf-local fallback" {
    var detail: cli.Detail = undefined;
    try std.testing.expectError(
        cli.Parse.FlagGroupViolation,
        cli.parse(root, &.{ "tool", "env-leaf" }, &detail),
    );
}

fn handleEnvKinds(args_ptr: *const anyopaque) anyerror!void {
    const args = cli.castArgs(root, &.{"env-kinds"}, args_ptr);
    handler_called = true;
    handler_enabled = args.enabled;
    handler_color = args.color;
    handler_label = args.label orelse "";
    handler_count = args.count orelse 0;
    handler_rate = args.rate orelse 0;
    handler_timeout = args.timeout orelse 0;
    handler_config = args.config orelse "";
    handler_format = args.format orelse "";
    handler_tags = args.tag;
    handler_levels = args.level;
}

test "runner env fallback reuses parser coercion for every supported flag kind" {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "env-kinds" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = envKinds,
    });

    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expect(handler_called);
    try std.testing.expect(handler_enabled);
    try std.testing.expect(!handler_color);
    try std.testing.expectEqualStrings("env-label", handler_label);
    try std.testing.expectEqual(@as(i64, 7), handler_count);
    try std.testing.expectEqual(@as(f64, 2.5), handler_rate);
    try std.testing.expectEqual(@as(u64, 10 * std.time.ns_per_min), handler_timeout);
    try std.testing.expectEqualStrings("/tmp/tool.conf", handler_config);
    try std.testing.expectEqualStrings("json", handler_format);
    try std.testing.expectEqual(@as(usize, 1), handler_tags.len);
    try std.testing.expectEqualStrings("alpha,beta", handler_tags[0]);
    try std.testing.expectEqual(@as(usize, 1), handler_levels.len);
    try std.testing.expectEqualStrings("high", handler_levels[0]);
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);
}

test "runner lets argv bool and list values win over env fallback" {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "env-kinds", "--enabled=false", "--color=true", "--tag", "cli-tag", "--level", "low" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = envKinds,
    });

    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expect(!handler_enabled);
    try std.testing.expect(handler_color);
    try std.testing.expectEqual(@as(usize, 1), handler_tags.len);
    try std.testing.expectEqualStrings("cli-tag", handler_tags[0]);
    try std.testing.expectEqual(@as(usize, 1), handler_levels.len);
    try std.testing.expectEqualStrings("low", handler_levels[0]);
}

fn invalidBoolEnv(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "TOOL_ENABLED")) return "maybe";
    return envKinds(name);
}

fn invalidIntEnv(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "TOOL_COUNT")) return "many";
    return envKinds(name);
}

fn invalidDurationEnv(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "TOOL_TIMEOUT")) return "later";
    return envKinds(name);
}

fn invalidChoiceEnv(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "TOOL_FORMAT")) return "xml";
    return envKinds(name);
}

fn invalidListEnv(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "TOOL_LEVEL")) return "medium";
    return envKinds(name);
}

fn expectInvalidEnvValue(
    env_lookup: *const fn (name: []const u8) ?[]const u8,
    flag: []const u8,
    raw: []const u8,
) !void {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "env-kinds" },
        .stdout = &stdout,
        .stderr = &stderr,
        .env_lookup = env_lookup,
    });

    try std.testing.expectEqual(@as(u8, 2), code);
    try std.testing.expect(!handler_called);
    try expectContains(stderr.buffered(), "invalid value");
    try expectContains(stderr.buffered(), flag);
    try expectContains(stderr.buffered(), raw);
}

test "runner invalid env values report parser invalid-value diagnostics" {
    try expectInvalidEnvValue(invalidBoolEnv, "--enabled", "maybe");
    try expectInvalidEnvValue(invalidIntEnv, "--count", "many");
    try expectInvalidEnvValue(invalidDurationEnv, "--timeout", "later");
    try expectInvalidEnvValue(invalidChoiceEnv, "--format", "xml");
    try expectInvalidEnvValue(invalidListEnv, "--level", "medium");
}

fn handleFail(_: *const anyopaque) anyerror!void {
    return error.IntentionalFailure;
}

test "runner dispatches a valid command and returns success" {
    reset();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "run", "--name", "consumer" },
        .stdout = &stdout,
        .stderr = &stderr,
    });

    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expect(handler_called);
    try std.testing.expectEqualStrings("consumer", handler_name);
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);
}

test "runner version and about write stdout and return success" {
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const version_code = try cli.run(root, .{
        .argv = &.{ "tool", "--version" },
        .stdout = &stdout,
        .stderr = &stderr,
        .version = "1.2.3",
    });
    try std.testing.expectEqual(@as(u8, 0), version_code);
    try std.testing.expectEqualStrings("1.2.3\n", stdout.buffered());

    stdout = std.Io.Writer.fixed(&stdout_buf);
    stderr = std.Io.Writer.fixed(&stderr_buf);
    const about_code = try cli.run(root, .{
        .argv = &.{ "tool", "about" },
        .stdout = &stdout,
        .stderr = &stderr,
        .version = "1.2.3",
        .about = "tool does work",
    });
    try std.testing.expectEqual(@as(u8, 0), about_code);
    try std.testing.expectEqualStrings("tool does work\n", stdout.buffered());
}

test "runner help and no-handler leaves write stdout with success" {
    var stdout_buf: [4096]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const help_code = try cli.run(root, .{
        .argv = &.{ "tool", "run", "--help" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 0), help_code);
    try expectContains(stdout.buffered(), "Run handler");
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);

    stdout = std.Io.Writer.fixed(&stdout_buf);
    stderr = std.Io.Writer.fixed(&stderr_buf);
    const no_handler_code = try cli.run(root, .{
        .argv = &.{ "tool", "help-only" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 0), no_handler_code);
    try expectContains(stdout.buffered(), "No handler help");
}

test "runner parse and handler errors use stderr and nonzero exit codes" {
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const parse_code = try cli.run(root, .{
        .argv = &.{ "tool", "run" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 2), parse_code);
    try expectContains(stderr.buffered(), "required flag missing");
    try std.testing.expectEqual(@as(usize, 0), stdout.buffered().len);

    stdout = std.Io.Writer.fixed(&stdout_buf);
    stderr = std.Io.Writer.fixed(&stderr_buf);
    const handler_code = try cli.run(root, .{
        .argv = &.{ "tool", "fail" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 1), handler_code);
    try expectContains(stderr.buffered(), "IntentionalFailure");
}

var hook_err_name: []const u8 = "";

fn onHandlerError(err: anyerror, stderr: *std.Io.Writer) anyerror!?u8 {
    hook_err_name = @errorName(err);
    try stderr.print("custom: {s}\n", .{@errorName(err)});
    return 42;
}

test "runner handler-error hook overrides message and exit code" {
    hook_err_name = "";
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "fail" },
        .stdout = &stdout,
        .stderr = &stderr,
        .on_handler_error = onHandlerError,
    });
    try std.testing.expectEqual(@as(u8, 42), code);
    try std.testing.expectEqualStrings("IntentionalFailure", hook_err_name);
    try expectContains(stderr.buffered(), "custom: IntentionalFailure");
}

test "runner warns on stderr when a deprecated command is invoked" {
    var stdout_buf: [4096]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "legacy" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 0), code);
    try expectContains(stderr.buffered(), "'legacy' is deprecated");
    try expectContains(stderr.buffered(), "use run");
}

test "runner warns on stderr when a deprecated flag is used" {
    reset();
    var stdout_buf: [4096]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "run", "--name", "x", "--old-name", "y" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 0), code);
    try expectContains(stderr.buffered(), "'--old-name' is deprecated");
    try expectContains(stderr.buffered(), "use --name");
}

test "runner stays quiet when a deprecated flag is absent" {
    reset();
    var stdout_buf: [4096]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buf);
    var stderr = std.Io.Writer.fixed(&stderr_buf);

    const code = try cli.run(root, .{
        .argv = &.{ "tool", "run", "--name", "x" },
        .stdout = &stdout,
        .stderr = &stderr,
    });
    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);
}

fn noColorLookup(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "NO_COLOR")) return "1";
    return null;
}

fn runHelpColor(color: cli.ColorMode, stdout_tty: bool, env_lookup: ?*const fn ([]const u8) ?[]const u8, buf: []u8) []const u8 {
    var stdout = std.Io.Writer.fixed(buf);
    var stderr_buf: [256]u8 = undefined;
    var stderr = std.Io.Writer.fixed(&stderr_buf);
    _ = cli.run(root, .{
        .argv = &.{ "tool", "run", "--help" },
        .stdout = &stdout,
        .stderr = &stderr,
        .color = color,
        .stdout_tty = stdout_tty,
        .env_lookup = env_lookup,
    }) catch unreachable;
    return stdout.buffered();
}

test "runner color policy: always/never/auto resolve as expected" {
    var buf: [8192]u8 = undefined;
    const esc = "\x1b[";

    // always → colorized regardless of TTY.
    try expectContains(runHelpColor(.always, false, null, &buf), esc);
    // never → never colorized, even on a TTY.
    try std.testing.expect(std.mem.indexOf(u8, runHelpColor(.never, true, null, &buf), esc) == null);
    // auto + no TTY → plain.
    try std.testing.expect(std.mem.indexOf(u8, runHelpColor(.auto, false, null, &buf), esc) == null);
    // auto + TTY → colorized.
    try expectContains(runHelpColor(.auto, true, null, &buf), esc);
    // auto + TTY but NO_COLOR set → plain.
    try std.testing.expect(std.mem.indexOf(u8, runHelpColor(.auto, true, noColorLookup, &buf), esc) == null);
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    try std.testing.expect(std.mem.indexOf(u8, haystack, needle) != null);
}
