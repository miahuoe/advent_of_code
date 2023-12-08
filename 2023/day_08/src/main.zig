const std = @import("std");

const Node = struct {
	this: usize,
	last: usize,
	left: usize,
	right: usize,

	pub fn id_from_str(str: []const u8) usize {
		var n: usize = 0;
		for (str) |c| {
			switch (c) {
			'A'...'Z' => {
				n = (n * 27) + (c - 'A');
			},
			else => {}, // TODO
			}
		}
		return n;
	}
};

pub fn parse_node(line: []u8) ?Node {
	var nums: [3]usize = undefined;
	var num: ?usize = 0;
	var last: usize = 0;
	var j: usize = 0;
	var i: usize = 0;
	for (line) |c| {
		switch (c) {
		'A'...'Z' => {
			if (num) |n| {
				num = (n * 27) + (c - 'A');
			} else {
				num = c - 'A';
			}
			if (i == 0 and j == 2) {
				last = c - 'A';
			}
			j += 1;
		},
		else => {
			if (num) |n| {
				nums[i] = n;
				i += 1;
				j = 0;
				num = null;
			}
		},
		}
	}
	if (i != 3) {
		return null;
	}
	return Node{.this = nums[0], .last = last, .left = nums[1], .right = nums[2]};
}

pub fn least_common_multiple(a: usize, b: usize) usize {
        var A: usize = a;
        var B: usize = b;
        while (A != B) {
                if (A > B) {
                        B += b;
                } else {
                        A += a;
                }
        }
        return A;
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const max_nodes = 27*27*27;
	var nodes: []Node = try allocator.alloc(Node, max_nodes);
	defer allocator.free(nodes);

	const stdin = std.io.getStdIn().reader();

	var path_buf: []u8 = try allocator.alloc(u8, 1024);
	defer allocator.free(path_buf);

	var buf: []u8 = try allocator.alloc(u8, 1024);
	defer allocator.free(buf);

	const path = try stdin.readUntilDelimiterOrEof(path_buf, '\n') orelse return;
	_ = try stdin.readUntilDelimiterOrEof(buf, '\n') orelse return;

	var ends_with_a = std.ArrayList(usize).init(allocator);
	defer ends_with_a.deinit();

	while (try stdin.readUntilDelimiterOrEof(buf, '\n')) |nline| {
		const n = parse_node(nline) orelse continue;
		nodes[n.this] = n;
		if (n.last == 0) {
			try ends_with_a.append(n.this);
		}
	}

	{
		var s: usize = 0;
		var p: usize = Node.id_from_str("AAA");
		var dst: usize = Node.id_from_str("ZZZ");
		while (true) : (s += 1) {
			const step = path[s % path.len];
			const n = nodes[p];
			if (n.this == dst) {
				break;
			}
			p = switch (step) {
			'L' => n.left,
			'R' => n.right,
			else => unreachable, // TODO
			};
		}
		std.log.debug("part 1: {d}", .{s});
	}

	var required_steps: ?usize = null;
	for (ends_with_a.items) |i| {
		var p = i;
		var s: usize = 0;
		while (true) : (s += 1) {
			const step = path[s % path.len];
			const n = nodes[p];
			if (n.last == 'Z'-'A') {
				break;
			}
			p = switch (step) {
			'L' => n.left,
			'R' => n.right,
			else => unreachable, // TODO
			};
		}
		if (required_steps) |rs| {
			required_steps = least_common_multiple(rs, s);
		} else {
			required_steps = s;
		}
	}
	std.log.debug("part 2: {?}", .{required_steps});
}

test "id of AAA" {
	const id = Node.id_from_str("AAA");
	try std.testing.expectEqual(id, 0);
}

test "id ZZZ" {
	const id = Node.id_from_str("ZZZ");
	try std.testing.expectEqual(id, 18925);
}

test "lcm" {
	try std.testing.expectEqual(least_common_multiple(2, 3), 6);
	try std.testing.expectEqual(least_common_multiple(7, 3), 21);
	try std.testing.expectEqual(least_common_multiple(1, 2), 2);
}

