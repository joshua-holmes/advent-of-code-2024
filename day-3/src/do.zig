const std = @import("std");

const Do = struct {};
const Dont = struct {};
const Mul = struct {
    a: i64,
    b: i64,
    fn calc(self: *const Mul) i64 {
        return self.a * self.b;
    }
};

const TokenUnion = union(enum) {
    do: Do,
    dont: Dont,
    mul: Mul,
};

const Token = enum {
    do,
    dont,
    mul,
};

const TrieSearchResult = union(enum) {
    token: Token,
    is_reset: bool,
};

const TrieSearch = struct {
    root: *Trie,
    trie: *Trie,

    fn new(trie: *Trie) TrieSearch {
        return TrieSearch{ .root = trie, .trie = trie };
    }

    fn search(self: *TrieSearch, char: u8) TrieSearchResult {
        if (self.trie.children.getPtr(char)) |t| {
            self.trie = t;
            if (t.token) |token| {
                self.trie = self.root;
                return .{ .token = token };
            }
        } else {
            self.trie = self.root;
            return .{ .is_reset = true };
        }
        return .{ .is_reset = false };
    }
};

const Trie = struct {
    children: std.AutoHashMap(u8, Trie),
    alloc: std.mem.Allocator,
    token: ?Token = null,

    fn searcher(self: *Trie) TrieSearch {
        return TrieSearch.new(self);
    }

    fn init(alloc: std.mem.Allocator) Trie {
        return Trie{
            .children = std.AutoHashMap(u8, Trie).init(alloc),
            .alloc = alloc,
        };
    }

    fn deinit(self: *Trie) void {
        var iter = self.children.valueIterator();
        while (iter.next()) |child| {
            child.deinit();
        }
        self.children.deinit();
    }

    fn set(self: *Trie, string: []const u8, token: Token) !void {
        var trie = self;
        for (string) |char| {
            const child: ?*Trie = trie.children.getPtr(char);
            if (child) |c| {
                trie = c;
            } else {
                try trie.children.put(char, Trie.init(self.alloc));
                trie = trie.children.getPtr(char).?;
            }
        }
        trie.token = token;
    }

    fn get(self: *const Trie, string: []const u8) ?Token {
        var trie = self;
        for (string) |char| {
            const child: ?*Trie = trie.children.getPtr(char);
            if (child) |c| {
                trie = c;
            } else {
                return null;
            }
        }
        return trie.token;
    }
};

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    var trie = Trie.init(alloc);
    defer trie.deinit();
    try trie.set("mul(*,*)", Token.mul);
    try trie.set("do()", Token.do);
    try trie.set("don't()", Token.dont);
    var searcher = trie.searcher();

    var i: usize = 0;
    var input1: ?i64 = null;
    var input2: ?i64 = null;
    var num = std.ArrayList(u8).init(alloc);
    defer num.deinit();

    var tokens = std.ArrayList(TokenUnion).init(alloc);
    defer tokens.deinit();

    while (i < input.len) {
        var found_number = false;
        while (input[i] >= '0' and input[i] <= '9') {
            found_number = true;
            try num.append(input[i]);
            i += 1;
        }
        if (found_number) {
            const n = try std.fmt.parseInt(i64, num.items, 10);
            num.clearRetainingCapacity();
            if (input1 == null) input1 = n else if (input2 == null) input2 = n;
        }
        const char = if (found_number) '*' else input[i];
        const result = searcher.search(char);
        switch (result) {
            .token => |t| {
                try tokens.append(switch (t) {
                    .do => TokenUnion{ .do = Do{} },
                    .dont => TokenUnion{ .dont = Dont{} },
                    .mul => TokenUnion{ .mul = Mul{ .a = input1.?, .b = input2.? } },
                });
                num.clearRetainingCapacity();
                input1 = null;
                input2 = null;
            },
            .is_reset => |ir| {
                if (ir) {
                    num.clearRetainingCapacity();
                    input1 = null;
                    input2 = null;
                }
            },
        }
        if (!found_number) i += 1;
    }

    var p1: i64 = 0;
    var p2: i64 = 0;
    var enabled = true;
    for (tokens.items) |t| {
        switch (t) {
            .mul => |m| {
                if (enabled) {
                    p2 += m.calc();
                }
                p1 += m.calc();
            },
            .do => enabled = true,
            .dont => enabled = false,
        }
    }
    std.debug.print("part 1 -> {d}\n", .{p1});
    std.debug.print("part 2 -> {d}\n", .{p2});
}

test "trie_do" {
    const alloc = std.testing.allocator;
    var trie = Trie.init(alloc);
    defer trie.deinit();
    try trie.set("do()", Token.do);

    try std.testing.expectEqual(trie.get("do()").?, Token.do);
}

test "trie_dont" {
    const alloc = std.testing.allocator;
    var trie = Trie.init(alloc);
    defer trie.deinit();
    try trie.set("don't()", Token.dont);

    try std.testing.expectEqual(trie.get("don't()").?, Token.dont);
}

test "trie_mul" {
    const alloc = std.testing.allocator;
    var trie = Trie.init(alloc);
    defer trie.deinit();
    try trie.set("mul(*,*)", Token.mul);

    try std.testing.expectEqual(trie.get("mul(*,*)").?, Token.mul);
}

test "trie_searcher_finds" {
    const alloc = std.testing.allocator;
    var trie = Trie.init(alloc);
    defer trie.deinit();
    try trie.set("do()", Token.do);
    var searcher = trie.searcher();

    for ("junk do()", 0..9) |char, i| {
        const search_result = searcher.search(char);
        if (char == ')') {
            try std.testing.expectEqual(search_result, TrieSearchResult{ .token = Token.do });
        } else if (i > 4) {
            try std.testing.expectEqual(search_result, TrieSearchResult{ .is_reset = false });
        } else {
            try std.testing.expectEqual(search_result, TrieSearchResult{ .is_reset = true });
        }
    }
}

test "trie_searcher_does_not_find" {
    const alloc = std.testing.allocator;
    var trie = Trie.init(alloc);
    defer trie.deinit();
    try trie.set("do()", Token.do);
    var searcher = trie.searcher();

    for ("junk dee()") |char| {
        const search_result = searcher.search(char);
        if (char == 'd') {
            try std.testing.expectEqual(search_result, TrieSearchResult{ .is_reset = false });
        } else {
            try std.testing.expectEqual(search_result, TrieSearchResult{ .is_reset = true });
        }
    }
}
