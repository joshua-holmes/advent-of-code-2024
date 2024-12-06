const std = @import("std");

fn is_report_safe(report: []i32) bool {
    var pre_n: ?i32 = null;
    var cur_n: ?i32 = null;
    var increasing: ?bool = null;
    for (0..report.len) |i| {
        pre_n = cur_n;
        cur_n = report[i];
        if (pre_n) |n| {
            const cur_increasing = n < cur_n.?;
            if (increasing == null) increasing = cur_increasing;
            const diff = @abs(n - cur_n.?);
            if (diff < 1 or diff > 3 or cur_increasing != increasing.?) {
                // fail
                return false;
            }
        }
    }
    return true;
}

fn is_report_safe_with_tolerance(report: []i32, alloc: std.mem.Allocator) !bool {
    if (is_report_safe(report)) return true;
    var modded_report = try std.ArrayList(i32).initCapacity(alloc, report.len - 1);
    for (0..report.len) |i| {
        try modded_report.appendSlice(report[0..i]);
        try modded_report.appendSlice(report[i + 1 ..]);
        if (is_report_safe(modded_report.items)) return true;
        modded_report.clearRetainingCapacity();
    }
    return false;
}

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    var safe1: u32 = 0;
    var safe2: u32 = 0;
    var num = std.ArrayList(u8).init(alloc);
    defer num.deinit();

    var line = std.ArrayList(i32).init(alloc);
    defer line.deinit();

    for (input) |char| {
        if (char == ' ' or char == '\n') {
            try line.append(try std.fmt.parseInt(i32, num.items, 10));

            num.clearRetainingCapacity();
            if (char == '\n') {
                // handle line
                if (is_report_safe(line.items)) safe1 += 1;
                if (try is_report_safe_with_tolerance(line.items, alloc)) safe2 += 1;
                line.clearRetainingCapacity();
            }
        } else {
            try num.append(char);
        }
    }

    std.debug.print("part 1 -> {d}\n", .{safe1});
    std.debug.print("part 2 -> {d}\n", .{safe2});
}
