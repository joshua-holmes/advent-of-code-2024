const std = @import("std");

/// Perform main business logic.
pub fn stuff(input: []u8) !void {
    std.debug.print("Hello world!\n{s}", .{input});
}
