const std = @import("std");
const unicode = std.unicode;

pub const double_top: u21 = 0x2550;
pub const single_vert: u21 = 0x2502;

pub fn titleLine(writer: anytype, title: []const u8, width: u8) !void {
    _ = title;
    for (0..width) |i| {
        _ = i;
        try writer.print("{u}", .{double_top});
    }
}
