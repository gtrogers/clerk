const std = @import("std");

pub const Kind = enum {
    active,
    upcoming,
    done,
    shelved,
    cancelled,
    any,
};

pub const Status = enum(u8) {
    unknown_or_quick = 0,
    doing = '>',
    monitoring = '?',
    todo = '.',
    shelved = '/',
    done = 'x',
    cancelled = '~',
    pub fn of(line: []const u8) Status {
        std.debug.assert(line.len > 1);
        return switch (line[0]) {
            '>' => Status.doing,
            '?' => Status.monitoring,
            '.' => Status.todo,
            '/' => Status.shelved,
            'x' => Status.done,
            '~' => Status.cancelled,
            else => Status.unknown_or_quick,
        };
    }
    pub fn matches(self: Status, kind: Kind) bool {
        return switch (kind) {
            Kind.active => self == .unknown_or_quick or self == .monitoring or self == .doing,
            Kind.upcoming => self == .unknown_or_quick or self == .todo,
            Kind.done => self == .done,
            Kind.shelved => self == .shelved,
            Kind.cancelled => self == .cancelled,
            Kind.any => true,
        };
    }
    pub fn toGlyph(self: Status) ?u8 {
        return switch (self) {
            .unknown_or_quick => null,
            .doing => '>',
            .monitoring => '?',
            .todo => '.',
            .shelved => '/',
            .done => 'x',
            .cancelled => '~',
        };
    }
};

pub const Task = struct {
    status: Status,
    content: []const u8,
    group_index: usize,
};

pub const Tasks = std.MultiArrayList(Task);
