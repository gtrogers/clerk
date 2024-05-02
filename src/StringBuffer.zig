const std = @import("std");
const assert = std.debug.assert;

/// StringBuffer: static buffer for holding an updatable
///               string value and checking equality
pub fn StringBuffer(comptime size: usize) type {
    return struct {
        size: usize = size,
        len: usize = 0,
        backing: [size]u8 = undefined,
        val: []const u8 = undefined,

        pub fn eql(self: @This(), str: []const u8) bool {
            return std.mem.eql(u8, self.val, str);
        }

        pub fn set(self: *@This(), str: []const u8) !void {
            if (str.len > self.size) return error.BufferTooSmall;

            for (0..str.len, str) |i, ch| {
                self.backing[i] = ch;
            }

            self.len = str.len;
            self.val = self.backing[0..self.len];
        }
    };
}

test "init to value" {
    const SB16 = StringBuffer(16);
    var sb: SB16 = .{};
    try sb.set("hello world");

    try std.testing.expectEqual(11, sb.len);
    try std.testing.expectEqualStrings("hello world", sb.val);
}

test "equality checking" {
    const SB16 = StringBuffer(16);
    var sb: SB16 = .{};
    try sb.set("hello world");

    try std.testing.expect(sb.eql("hello world"));
    try std.testing.expect(!sb.eql("blah blah blah"));
}

test "update string value" {
    const SB16 = StringBuffer(16);
    var sb: SB16 = .{};
    try sb.set("woozle");

    try std.testing.expect(sb.eql("woozle"));

    try sb.set("foo");
    try std.testing.expectEqual(3, sb.len);
    try std.testing.expectEqualStrings("foo", sb.val);
    try std.testing.expect(sb.eql("foo"));
}

test "errors if too long" {
    const SB8 = StringBuffer(8);
    var sb: SB8 = .{};

    const result = sb.set("123456789");

    try std.testing.expectError(error.BufferTooSmall, result);
}
