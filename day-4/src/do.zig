const std = @import("std");

const Direction = enum {
    up_left,
    up,
    up_right,
    right,
    down_right,
    down,
    down_left,
    left,

    fn all() [8]Direction {
        return .{
            Direction.up_left,
            Direction.up,
            Direction.up_right,
            Direction.right,
            Direction.down_right,
            Direction.down,
            Direction.down_left,
            Direction.left,
        };
    }
};

const Point = struct {
    x: isize,
    y: isize,

    fn go(self: *const Point, direction: Direction, size: *const Point) ?Point {
        const point = switch (direction) {
            .up_left => Point{ .x = self.x - 1, .y = self.y - 1 },
            .up => Point{ .x = self.x, .y = self.y - 1 },
            .up_right => Point{ .x = self.x + 1, .y = self.y - 1 },
            .right => Point{ .x = self.x + 1, .y = self.y },
            .down_right => Point{ .x = self.x + 1, .y = self.y + 1 },
            .down => Point{ .x = self.x, .y = self.y + 1 },
            .down_left => Point{ .x = self.x - 1, .y = self.y + 1 },
            .left => Point{ .x = self.x - 1, .y = self.y },
        };

        if (point.x < 0 or point.y < 0 or point.x >= size.x or point.y >= size.y)
            return null;

        return point;
    }

    fn to_index(self: *const Point, size: *const Point) usize {
        return @intCast((size.y * self.y) + self.x);
    }
};

fn search(chars: []const u8, direction: Direction, from: *const Point, size: *const Point, string: []const u8, string_i: usize) bool {
    const input_char = chars[from.to_index(size)];
    const comp_char = string[string_i];
    if (input_char == comp_char) {
        if (string.len == 1 or (string_i > 0 and string_i + 1 >= string.len)) {
            return true;
        }
        const new_point = from.go(direction, size);
        if (new_point) |p| {
            return search(chars, direction, &p, size, string, string_i + 1);
        }
    }

    return false;
}

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    // stores list of letters A-Z or a-z
    var chars = std.ArrayList(u8).init(alloc);

    // size of grid of letters
    var x_size: isize = 0;
    var y_size: isize = 0;

    // iterate through input and extract only letters and put them into `chars`
    // also count size of grid
    var counting_x = true;
    for (input) |char| {
        if (char == '\n') {
            counting_x = false;
            y_size += 1;
        }
        if (char >= 'A' and char <= 'z') {
            if (counting_x) x_size += 1;
            try chars.append(char);
        }
    }

    // size of grid of letters
    const size = Point{ .x = x_size, .y = y_size };

    // iterate through grid and search for "XMAS" in each direciton at each coordinate
    var p1: usize = 0;
    const target = "XMAS";
    for (0..@intCast(size.y)) |y| {
        for (0..@intCast(size.x)) |x| {
            const point = Point{ .x = @intCast(x), .y = @intCast(y) };
            // if this point in the grid doesn't match the first character of our target, skip
            if (chars.items[point.to_index(&size)] != target[0])
                continue;
            for (Direction.all()) |dir| {
                if (search(chars.items, dir, &point, &size, target, 0))
                    p1 += 1;
            }
        }
    }

    std.debug.print("{any}\n", .{p1});
}
