const std = @import("std");

const tasks = @import("./tasks.zig");

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
            // TODO - we maybe want to track these lines for efficient
            //        file editing, currently discarding them
            if (line.len < 2) continue;
            if (line[0] == ':') {
                try groups.append(line[2..]);
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

pub fn printActiveTasks(task_file: TaskFile) void {
    var group_no: usize = 0;
    for (task_file.list.items(.status), task_file.list.items(.content), task_file.list.items(.group_index)) |s, c, gi| {
        // TODO - use buffered writer here
        if (s.isActive()) {
            if (gi > group_no) {
                std.debug.print("\n-- {s}\n", .{task_file.groups.items[gi]});
                group_no = gi;
            }

            const status_glyph = s.toGlyph();
            if (status_glyph) |sg| {
                std.debug.print("{c}", .{sg});
            }

            std.debug.print(" {s}\n", .{c});
        }
    }

    std.debug.print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    if (try TaskFile.init(allocator, "./tasks.clerk")) |*project_tasks| {
        std.debug.print("PROJECT TASKS\n", .{});
        var todos = project_tasks.*;
        defer todos.deinit();
        printActiveTasks(project_tasks.*);
    }

    const home_dir = try std.process.getEnvVarOwned(allocator, "HOME");
    defer allocator.free(home_dir);
    const parts: [2][]const u8 = .{ home_dir, "tasks.clerk" };
    const user_tasks_path = try std.fs.path.join(allocator, &parts);
    defer allocator.free(user_tasks_path);

    if (try TaskFile.init(allocator, user_tasks_path)) |*user_tasks| {
        std.debug.print("PERSONAL TASKS\n", .{});
        var todos = user_tasks.*;
        defer todos.deinit();
        printActiveTasks(user_tasks.*);
    }
}

test "reading file to list" {
    const ally = std.testing.allocator;

    var t = try TaskFile.init(ally, "./tasks.clerk");
    defer t.?.deinit();
}
