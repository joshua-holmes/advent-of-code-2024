const std = @import("std");

const Point = struct {
    x: i32,
    y: i32,

    fn from_index(index: usize, width: usize) Point {
        return Point{
            .x = @intCast(index % width),
            .y = @intCast(index / width),
        };
    }

    fn to_index(self: *const Point, width: usize, height: usize) ?usize {
        if (self.x < 0 or self.y < 0 or self.x >= width or self.y >= height) return null;
        const w: i32 = @intCast(width);
        return @intCast(self.y * w + self.x);
    }
};

const Grid = struct {
    height: usize,
    width: usize,
    items: std.ArrayList(u8),
    guard_i: usize,

    const guard: [4]u8 = .{ '^', '>', '<', 'v' };

    fn print(self: *const Grid) void {
        std.debug.print("\nGRID\n", .{});
        for (self.items.items, 0..self.items.items.len) |char, i| {
            std.debug.print("{c}", .{char});
            if (i % self.width == self.width - 1) std.debug.print("\n", .{});
        }
    }

    fn get(self: *const Grid, point: *const Point) ?u8 {
        const index = point.to_index(self.width, self.height) orelse return null;
        return self.items.items[index];
    }

    fn init(input: []u8, alloc: std.mem.Allocator) !Grid {
        var width: usize = 0;
        var height: usize = 0;
        var items = std.ArrayList(u8).init(alloc);
        var count_width = true;
        var guard_i: ?usize = null;
        for (input) |char| {
            if (char == '\n') {
                count_width = false;
                height += 1;
            } else {
                try items.append(char);
            }
            if (count_width) width += 1;
            for (guard) |g| {
                if (char == g) guard_i = items.items.len - 1;
            }
        }
        if (guard_i == null) return error.GuardNotFound;

        return Grid{
            .width = width,
            .height = height,
            .items = items,
            .guard_i = guard_i.?,
        };
    }

    fn deinit(self: *Grid) void {
        self.items.deinit();
    }
};

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    var grid = try Grid.init(input, alloc);
    defer grid.deinit();

    var i = grid.guard_i;
    outer: while (true) {
        while (true) {
            var next = Point.from_index(i, grid.width);
            const guard = grid.items.items[i];
            switch (guard) {
                '^' => next.y -= 1,
                '>' => next.x += 1,
                '<' => next.x -= 1,
                'v' => next.y += 1,
                else => unreachable,
            }
            if (grid.get(&next)) |char| {
                if (char == '.' or char == 'X') {
                    // move guard
                    grid.items.items[i] = 'X';
                    i = next.to_index(grid.width, grid.height).?;
                    grid.items.items[i] = guard;
                    continue :outer;
                } else {
                    // guard ran into wall, rotate 90 deg
                    switch (guard) {
                        '^' => {
                            grid.items.items[i] = '>';
                        },
                        '>' => {
                            grid.items.items[i] = 'v';
                        },
                        '<' => {
                            grid.items.items[i] = '^';
                        },
                        'v' => {
                            grid.items.items[i] = '<';
                        },
                        else => unreachable,
                    }
                }
            } else {
                // guard left map, exit loop
                grid.items.items[i] = 'X';
                break :outer;
            }
        }
    }

    var p1: u32 = 0;
    for (grid.items.items) |char| {
        if (char == 'X') p1 += 1;
    }

    std.debug.print("part 1 = {d}\n", .{p1});
}
