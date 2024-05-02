const std = @import("std");

pub const Status = enum {
    unknown,
    not_started,
    doing,
    done,
    shelved,
    monitoring,
    cancelled,
    pub fn toGlyph(self: Status) u8 {
        return switch (self) {
            .unknown => ' ',
            .not_started => '.',
            .doing => '>',
            .done => 'x',
            .shelved => '/',
            .monitoring => '?',
            .cancelled => '~',
        };
    }
};

pub const Task = struct {
    status: Status,
    content: []const u8,
    group: ?[]const u8,
};

pub const Tasks = std.MultiArrayList(Task);

pub fn get_status(line: []u8) Status {
    return switch (line[0]) {
        '.' => Status.not_started,
        '>' => Status.doing,
        'x' => Status.done,
        '/' => Status.shelved,
        '?' => Status.monitoring,
        '~' => Status.cancelled,
        else => Status.unknown,
    };
}

pub fn is_group(line: []const u8) bool {
    return line[0] == ':';
}

const MAX_LINE_SIZE = 1024 * 8;
const MAX_TASKS = 1024;

pub const TaskReader = struct {
    i: usize = 0,
    reader: *std.io.Reader,
    raw_lines: [MAX_TASKS][]const u8 = undefined,
    buffer: [MAX_LINE_SIZE]u8 = undefined,
    current_group: []const u8 = "none",

    pub fn init(reader: *std.io.Reader) TaskReader {
        return .{ .reader = reader };
    }

    pub fn deinit(self: *TaskReader) void {
        for (0..self.i) |i| {
            self.allocator.free(self.raw_lines[i]);
        }
    }

    pub fn next(self: *TaskReader) !?Task {
        while (self.reader.readUntilDelimiterOrEof(&self.buffer, '\n')) |line| {
            if (line.len <= 2) continue;

            const current = self.i;
            self.raw_lines[current] = try self.allocator.dupe(u8, line);
            self.i += 1;

            if (is_group(line)) {
                self.current_group = self.raw_lines[current][2..];
                continue;
            }

            const status = get_status(line);

            return .{
                .status = status,
                .group = self.current_group,
                .content = if (status == Status.unknown) self.raw_line[current][0..] else self.raw_line[current][2..],
            };
        }
    }
};
