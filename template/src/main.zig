const std = @import("std");
const do = @import("do.zig");

const MAX_SIZE = 1_000_000_000;

pub fn main() !void {
    // setup file
    const file = std.fs.cwd().openFile("input", .{ .mode = .read_only }) catch |e| {
        std.debug.print("Failed to open file with: {any}\n", .{e});
        return e;
    };
    defer file.close();

    // setup allocator
    var gp = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gp.allocator();

    // read file
    const input = try file.readToEndAlloc(alloc, MAX_SIZE);
    defer alloc.free(input);

    // perform business logic
    try do.stuff(input);
}
