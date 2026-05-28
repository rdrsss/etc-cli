//! Shared command/flag metadata.

pub const Deprecation = struct {
    message: []const u8 = "",
    replacement: ?[]const u8 = null,
};
