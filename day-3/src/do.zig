const std = @import("std");

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    var p1: i64 = 0;
    const format = "mul(d,d)";
    var f_i: usize = 0;
    var i_i: usize = 0;
    var input1: ?i64 = null;
    var input2: ?i64 = null;
    var num = std.ArrayList(u8).init(alloc);
    defer num.deinit();
    while (i_i < input.len) {
        const char = input[i_i];
        const f_char = format[f_i];
        if (f_char == 'd') {
            // digit
            while (i_i < input.len and input[i_i] >= '0' and input[i_i] <= '9') {
                try num.append(input[i_i]);
                i_i += 1;
            }
            const n = std.fmt.parseInt(i64, num.items, 10) catch {
                f_i = 0;
                i_i += 1;
                input1 = null;
                input2 = null;
                num.clearRetainingCapacity();
                continue;
            };
            if (input1 == null) {
                input1 = n;
                f_i += 1;
                num.clearRetainingCapacity();
                continue;
            } else if (input2 == null) {
                input2 = n;
                f_i += 1;
                num.clearRetainingCapacity();
                continue;
            } else {
                f_i = 0;
                i_i += 1;
                input1 = null;
                input2 = null;
                num.clearRetainingCapacity();
                continue;
            }
        } else if (f_char != char or char == ')') {
            if (char == ')' and input1 != null and input2 != null) {
                p1 += input1.? * input2.?;
            }
            f_i = 0;
            i_i += 1;
            input1 = null;
            input2 = null;
            num.clearRetainingCapacity();
            continue;
        }
        f_i += 1;
        i_i += 1;
    }
    std.debug.print("part 1 -> {d}\n", .{p1});
}
