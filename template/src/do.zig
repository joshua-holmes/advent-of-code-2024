const std = @import("std");

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    _ = alloc;
    std.debug.print("Hello world!\n{s}", .{input});
}
