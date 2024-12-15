const std = @import("std");

fn HashSet(T: type) type {
    return std.AutoHashMap(T, void);
}

const RulePair = struct {
    before: u32,
    after: u32,
};

const RuleSet = struct {
    before: HashSet(u32),
    after: HashSet(u32),

    fn init(alloc: std.mem.Allocator) RuleSet {
        return RuleSet{
            .before = HashSet(u32).init(alloc),
            .after = HashSet(u32).init(alloc),
        };
    }

    fn deinit(self: *RuleSet) void {
        self.after.deinit();
        self.before.deinit();
    }
};

fn parse_section_1(input: []u8, alloc: std.mem.Allocator) !std.ArrayList(RulePair) {
    // simply parse through section 1 and get rule pairs
    var section = std.ArrayList(RulePair).init(alloc);
    var num = std.ArrayList(u8).init(alloc);
    var is_before = true;
    var before: ?u32 = null;
    var last_char: ?u8 = null;
    for (input) |char| {
        if (char >= '0' and char <= '9') {
            try num.append(char);
        } else if (char == '|') {
            before = try std.fmt.parseInt(u32, num.items, 10);
            is_before = false;
            num.clearRetainingCapacity();
        } else if (char == '\n') {
            if (last_char) |lc| {
                // double '\n' means end of section, so exit
                if (lc == '\n') {
                    return section;
                }
            }
            if (before) |b| {
                try section.append(RulePair{
                    .before = b,
                    .after = try std.fmt.parseInt(u32, num.items, 10),
                });
            }
            is_before = true;
            before = null;
            num.clearRetainingCapacity();
        }
        last_char = char;
    }
    return section;
}

fn make_rules(rules_pairs: []const RulePair, alloc: std.mem.Allocator) !std.AutoHashMap(u32, RuleSet) {
    // use rule pairs to create HashSet of `after` numbers and `before` numbers for each number
    var rules = std.AutoHashMap(u32, RuleSet).init(alloc);
    for (rules_pairs) |rc| {
        var rule = try rules.getOrPut(rc.before);
        if (!rule.found_existing) {
            rule.value_ptr.* = RuleSet.init(alloc);
        }
        try rule.value_ptr.after.put(rc.after, {});

        rule = try rules.getOrPut(rc.after);
        if (!rule.found_existing) {
            rule.value_ptr.* = RuleSet.init(alloc);
        }
        try rule.value_ptr.before.put(rc.before, {});
    }

    return rules;
}

fn parse_section_2(input: []u8, alloc: std.mem.Allocator) !std.ArrayList(std.ArrayList(u32)) {
    // find index of section 2
    var last_char: ?u8 = null;
    var index: ?usize = null;
    for (0..input.len, input) |i, char| {
        if (last_char) |lc| {
            if (char == '\n' and lc == '\n') {
                index = i + 1;
                break;
            }
        }
        last_char = char;
    }
    if (index == null) @panic("Sections must be separated by double '\n\'");

    // simply parse list of numbers and turn it into ArrayList of u32
    var updates = std.ArrayList(std.ArrayList(u32)).init(alloc);
    var page = std.ArrayList(u32).init(alloc);
    var num = std.ArrayList(u8).init(alloc);
    for (input[index.?..]) |char| {
        if (char >= '0' and char <= '9') {
            try num.append(char);
        } else if (char == ',') {
            try page.append(try std.fmt.parseInt(u32, num.items, 10));
            num.clearRetainingCapacity();
        } else {
            try page.append(try std.fmt.parseInt(u32, num.items, 10));
            num.clearRetainingCapacity();
            try updates.append(page);
            page = std.ArrayList(u32).init(alloc);
        }
    }
    if (updates.getLast().items.len != page.items.len) {
        page.deinit();
    }
    return updates;
}

// for part 2
fn reorder_and_return_mid(update: []u32, rule_sets: *const std.AutoHashMap(u32, RuleSet)) u32 {
    for (update, 0..update.len) |page, i| {
        if (rule_sets.get(page)) |rule| {
            for (0..update.len) |j| {
                if (i == j) continue;
                const set = if (j > i) rule.before else rule.after;
                // if `update.items[j]` is found before `page` and found in the `after` list, it's a violation`
                if (set.get(update[j]) != null) {
                    update[i] = update[j];
                    update[j] = page;
                    return reorder_and_return_mid(update, rule_sets);
                }
            }
        }
    }
    const index = (update.len / 2) - ((update.len + 1) % 2);
    return update[index];
}

/// Perform main business logic.
pub fn stuff(input: []u8, alloc: std.mem.Allocator) !void {
    const rule_pairs = try parse_section_1(input, alloc);
    defer rule_pairs.deinit();
    var rules = try make_rules(rule_pairs.items, alloc);
    defer {
        var iter = rules.valueIterator();
        while (iter.next()) |rs| rs.deinit();
        rules.deinit();
    }
    const updates = try parse_section_2(input, alloc);
    defer {
        for (updates.items) |update| update.deinit();
        updates.deinit();
    }

    // for each page in each update, iterate through neighbor pages and find any rule violations
    var p1: u32 = 0;
    var p2: u32 = 0;
    update_blk: for (updates.items) |update| {
        for (update.items, 0..update.items.len) |page, i| {
            if (rules.get(page)) |rule| {
                for (0..update.items.len) |j| {
                    if (i == j) continue;
                    const set = if (j > i) rule.before else rule.after;
                    // if `update.items[j]` is found before `page` and found in the `after` list, it's a violation`
                    if (set.get(update.items[j]) != null) {
                        var update_copy = try std.ArrayList(u32).initCapacity(alloc, update.items.len);
                        defer update_copy.deinit();
                        for (update.items) |p| try update_copy.append(p);
                        p2 += reorder_and_return_mid(update_copy.items, &rules);
                        continue :update_blk;
                    }
                }
            }
        }
        // index of middle
        const index = (update.items.len / 2) - ((update.items.len + 1) % 2);
        p1 += update.items[index];
    }

    std.debug.print("part 1 -> {d}\n", .{p1});
    std.debug.print("part 2 -> {d}\n", .{p2});
}
