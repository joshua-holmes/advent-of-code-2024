const std = @import("std");

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    var list1 = std.ArrayList(u32).init(alloc);
    defer list1.deinit();
    var list2 = std.ArrayList(u32).init(alloc);
    defer list2.deinit();
    {
        var num1 = std.ArrayList(u8).init(alloc);
        var num2 = std.ArrayList(u8).init(alloc);
        var is_left = true;
        for (input) |char| {
            if (char >= '0' and char <= '9') {
                if (is_left) try num1.append(char) else try num2.append(char);
            } else if (char == ' ') {
                is_left = false;
            } else if (char == '\n') {
                is_left = true;
                try list1.append(try std.fmt.parseInt(u32, num1.items, 10));
                try list2.append(try std.fmt.parseInt(u32, num2.items, 10));
                num1.clearRetainingCapacity();
                num2.clearRetainingCapacity();
            }
        }
    }

    std.mem.sort(u32, list1.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, list2.items, {}, std.sort.asc(u32));

    var sum: u32 = 0;
    for (list1.items, list2.items) |n1, n2| {
        sum += if (n1 > n2) n1 - n2 else n2 - n1;
    }

    std.debug.print("{d}\n", .{sum});
}
