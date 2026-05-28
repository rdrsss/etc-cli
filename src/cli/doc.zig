//! Manual-oriented documentation metadata.
//!
//! These structs are parser-neutral. They enrich generated documentation but
//! do not change argv parsing, dispatch, or generated argument types.

pub const Doc = struct {
    examples: []const Example = &.{},
    exit_codes: []const ExitCode = &.{},
    see_also: []const []const u8 = &.{},
    notes: []const []const u8 = &.{},
};

pub const Example = struct {
    title: []const u8 = "",
    command: []const u8,
    desc: []const u8 = "",
};

pub const ExitCode = struct {
    code: u8,
    desc: []const u8,
};
