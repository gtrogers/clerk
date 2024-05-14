const std = @import("std");

const tasks = @import("./tasks.zig");
const cli = @import("./cli.zig");
const line_art = @import("./line-art.zig");

const TaskFile = struct {
    allocator: std.mem.Allocator,
    buff: []const u8,
    list: tasks.Tasks,
    groups: std.ArrayList([]const u8),
    pub fn init(a: std.mem.Allocator, file_path: []const u8) !?TaskFile {
        const f = std.fs.cwd().openFile(file_path, .{}) catch |err| switch (err) {
            error.FileNotFound => return null,
            else => return err,
        };

        const stat = try f.stat();
        const buff = try f.readToEndAlloc(a, stat.size);
        var list = tasks.Tasks{};
        var groups = std.ArrayList([]const u8).init(a);
        try groups.append("None");
        var current_group: usize = 0;
        var split = std.mem.split(u8, buff, "\n");
        while (split.next()) |line| {
            if (line.len < 2) continue;
            if (line[0] == ':') {
                try groups.append(line[3..]);
                current_group += 1;
            } else {
                const status = tasks.Status.of(line);
                const task_line = switch (status) {
                    tasks.Status.unknown_or_quick => line[0..],
                    else => line[2..],
                };
                try list.append(a, .{ .status = status, .content = task_line, .group_index = current_group });
            }
        }

        return .{ .allocator = a, .buff = buff, .list = list, .groups = groups };
    }
    pub fn deinit(self: *TaskFile) void {
        self.allocator.free(self.buff);
        self.list.deinit(self.allocator);
        self.groups.deinit();
    }
};

fn inSlice(comptime T: type, s: []T, val: T) bool {
    for (s) |item| {
        if (item == val) {
            return true;
        }
    }
    return false;
}

pub fn printTasks(task_file: TaskFile, k: tasks.Kind, writer: anytype) !void {
    var group_no: usize = 0;
    var written = false;
    for (task_file.list.items(.status), task_file.list.items(.content), task_file.list.items(.group_index)) |s, c, gi| {
        if (s.matches(k)) {
            if (!written) written = true;
            if (gi > group_no) {
                try writer.print("\t{s}\n", .{task_file.groups.items[gi]});
                group_no = gi;
            }

            try writer.print("\t  ", .{});
            const status_glyph = s.toGlyph();
            if (status_glyph) |sg| {
                try writer.print("{c} ", .{sg});
            }

            try writer.print("{s}\n", .{c});
        }
    }

    if (!written) try writer.print("\tNo active tasks!", .{});
    try writer.print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    const std_out = std.io.getStdOut();
    var buf = std.io.bufferedWriter(std_out.writer());
    const writer = buf.writer();

    const mode = try cli.readArgsAlloc(allocator);

    switch (mode) {
        cli.Mode.show_active, cli.Mode.show_upcoming => {
            const kind = switch (mode) {
                cli.Mode.show_active => tasks.Kind.active,
                cli.Mode.show_upcoming => tasks.Kind.upcoming,
                else => unreachable,
            };
            if (try TaskFile.init(allocator, "./tasks.clerk")) |*project_tasks| {
                var todos = project_tasks.*;
                defer todos.deinit();

                try writer.print("\tPROJECT TASKS\n", .{});
                try printTasks(todos, kind, &writer);
            }

            const home_dir = try std.process.getEnvVarOwned(allocator, "HOME");
            defer allocator.free(home_dir);
            const parts: [2][]const u8 = .{ home_dir, "tasks.clerk" };
            const user_tasks_path = try std.fs.path.join(allocator, &parts);
            defer allocator.free(user_tasks_path);

            if (try TaskFile.init(allocator, user_tasks_path)) |*user_tasks| {
                var todos = user_tasks.*;
                defer todos.deinit();

                try writer.print("\n\tPERSONAL TASKS\n", .{});
                try printTasks(todos, kind, &writer);
            }
        },
        cli.Mode.tidy => std.debug.print("Not yet implemented!", .{}),
        cli.Mode.help => std.debug.print("Some useful help text", .{}),
    }

    try writer.print("\n", .{});
    try buf.flush();
}

test "reading file to list" {
    const ally = std.testing.allocator;

    var t = try TaskFile.init(ally, "./tasks.clerk");
    defer t.?.deinit();
}
