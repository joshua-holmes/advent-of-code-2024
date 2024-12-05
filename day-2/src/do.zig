const std = @import("std");

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    var safe: u32 = 0;
    var num = std.ArrayList(u8).init(alloc);
    defer num.deinit();
    var last_n: ?i32 = null;
    var cur_n: ?i32 = null;
    var increasing: ?bool = null;
    var i: usize = 0;
    while (i < input.len) {
        const char = input[i];
        if (char == ' ' or char == '\n') {
            last_n = cur_n;
            cur_n = try std.fmt.parseInt(i32, num.items, 10);
            num.clearRetainingCapacity();
            if (last_n) |n| {
                const diff = @abs(cur_n.? - n);
                const cur_increasing = cur_n.? > n;
                if (increasing == null) increasing = cur_increasing;
                if (diff < 1 or diff > 3 or increasing != cur_increasing) {
                    // unsafe
                    while (input[i] != '\n') i += 1;
                    last_n = null;
                    cur_n = null;
                    increasing = null;
                } else if (char == '\n') {
                    // safe
                    safe += 1;
                    last_n = null;
                    cur_n = null;
                    increasing = null;
                }
            }
        } else {
            try num.append(char);
        }
        i += 1;
    }
    std.debug.print("part 1 -> {d}\n", .{safe});
}
