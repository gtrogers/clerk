const std = @import("std");

pub const Mode = enum {
    show_active,
    tidy,
    help,
    pub fn parse(args: [][]u8) Mode {
        if (args.len == 1) return .show_active;
        const arg_of_note = args[1];

        if (std.mem.eql(u8, "tidy", arg_of_note)) return .tidy;
        return .help;
    }
};

pub fn readArgsAlloc(a: std.mem.Allocator) !Mode {
    const args = try std.process.argsAlloc(a);
    defer std.process.argsFree(a, args);

    return Mode.parse(args);
}
