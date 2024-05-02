const std = @import("std");
const process = std.process;
const path = std.fs.path;

const tasks = @import("./tasks.zig");
const StringBuffer = @import("./StringBuffer.zig").StringBuffer;
const SB2048 = StringBuffer(2048);

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const MAX_LINE_SIZE = 1024 * 8;
const MAX_TASKS = 1024;

const Clerk = struct {
    _allocator: std.mem.Allocator,
    raw_lines: [MAX_TASKS][]const u8 = undefined,
    raw_lines_cursor: usize = 0,
    homeDirFile: []const u8,
    userTasks: tasks.Tasks = .{},
    project_file: ?[]const u8,
    project_tasks: tasks.Tasks = .{},

    pub fn init(allocator: std.mem.Allocator, home_file: []const u8, project_file: ?[]const u8) !Clerk {
        _ = project_file;
        return .{ ._allocator = allocator, .homeDirFile = home_file };
    }

    pub fn deinit(self: *Clerk) void {
        self.userTasks.deinit(self._allocator);
        for (0..self.raw_lines_cursor) |i| {
            self._allocator.free(self.raw_lines[i]);
        }
    }

    pub fn readProjectTasks(self: *Clerk) !void {
        if (self.project_file) |f_path| {
            const f = try std.fs.openFileAbsolute(f_path, .{});
            var b_reader = std.io.bufferedReader(f.reader());
            var stream = b_reader.reader();
            var buffer: [MAX_LINE_SIZE]u8 = undefined;
            var group: ?[]const u8 = null;
            while (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
                if (line.len <= 2) continue;
                const new_line: []const u8 = try self._allocator.dupe(u8, line);
                self.raw_lines[self.raw_lines_cursor] = new_line;
                self.raw_lines_cursor += 1;

                
                
            }
        } else {
            return error.NoProjectFileFound;
        }
    }

    pub fn readTasks(self: *Clerk) !void {
        // TODO - offload parsing code somewhere else, it will only get messier
        const f = try std.fs.openFileAbsolute(self.homeDirFile, .{});
        var b_reader = std.io.bufferedReader(f.reader());
        var stream = b_reader.reader();
        var buffer: [MAX_LINE_SIZE]u8 = undefined;
        var group: ?[]const u8 = null;
        while (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (line.len <= 2) continue;
            const new_line: []const u8 = try self._allocator.dupe(u8, line);
            self.raw_lines[self.raw_lines_cursor] = new_line;
            self.raw_lines_cursor += 1;

            if (tasks.isGroupLine(new_line)) {
                group = new_line[2..];
                continue;
            }

            const status = tasks.getStatus(line);
            var content: []const u8 = undefined;
            if (status == tasks.Status.unknown) {
                content = new_line;
            } else {
                content = new_line[2..];
            }
            // TODO - better parsing logic (e.g. split on white space)
            try self.userTasks.append(self._allocator, .{ .status = status, .content = content, .group = group });
        }
    }
    pub fn default(self: *Clerk) !void {
        const stdout = std.io.getStdOut();
        var bw = std.io.bufferedWriter(stdout.writer());
        var out = bw.writer();
        var sb: SB2048 = .{};
        try sb.set("NO GROUP");
        for (self.userTasks.items(.status), self.userTasks.items(.content), self.userTasks.items(.group)) |s, c, g| {
            switch (s) {
                tasks.Status.unknown, tasks.Status.doing, tasks.Status.monitoring => {
                    if (g) |group| {
                        if (!sb.eql(group)) {
                            try out.print("\n-- {s}\n", .{group});
                            try sb.set(group);
                        }
                    }
                    try out.print("{c} {s}\n", .{ s.toGlyph(), c });
                },
                else => {},
            }
        }
        try bw.flush();
    }
};

fn findHome(allocator: std.mem.Allocator) ![]const u8 {
    const homeDir = try process.getEnvVarOwned(allocator, "HOME");
    defer allocator.free(homeDir);

    const paths: [2][]const u8 = .{ homeDir, "todo.clerk" };
    return try path.join(allocator, &paths);
}

fn findProject(allocator: std.mem.Allocator) ?[]const u8 {
    const project_dir = std.fs.cwd();
    return project_dir.realpathAlloc(allocator, "tasks.clerk") catch null;
}

pub fn main() !void {
    const allocator = gpa.allocator();

    const home_file = try findHome(allocator);
    defer allocator.free(home_file);

    const project_file = findProject(allocator);
    if (project_file) |f| {
        defer allocator.free(f);
    }

    var clerk = try Clerk.init(allocator, home_file, "some/project/file");
    defer clerk.deinit();

    clerk.readTasks() catch {
        std.debug.print("Could not read Clerk file, does it exist?", .{});
        process.exit(255);
    };

    try clerk.default();
}

test "init/deinit test" {
    const allocator = std.testing.allocator;
    var cwd = std.fs.cwd();
    const p = try cwd.realpathAlloc(allocator, "./test/example.clerk");
    defer allocator.free(p);
    var clerk = try Clerk.init(allocator, p, "foo");
    defer clerk.deinit();
}

test "file parsing" {
    // TODO: pass file location into init func
    const allocator = std.testing.allocator;
    var cwd = std.fs.cwd();
    const p = try cwd.realpathAlloc(allocator, "./test/example.clerk");
    defer allocator.free(p);
    var clerk = try Clerk.init(allocator, p, "foo");
    defer clerk.deinit();

    try clerk.readTasks();
    try clerk.default();
}
