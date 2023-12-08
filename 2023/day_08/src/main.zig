const std = @import("std");

const num_letters = 'Z'-'A'+1;

const Node = struct {
	left: u16,
	right: u16,
	last: u16,

	pub fn id_from_str(str: []const u8) usize {
		var n: usize = 0;
		for (str) |c| {
			switch (c) {
			'A'...'Z' => {
				n = (n * num_letters) + (c - 'A');
			},
			else => {}, // TODO
			}
		}
		return n;
	}

	pub fn parse(line: []u8) ?NodeWithId {
		var nums: [3]u16 = undefined;
		var num: ?u16 = 0;
		var last: u16 = 0;
		var j: usize = 0;
		var i: usize = 0;
		for (line) |c| {
			switch (c) {
			'A'...'Z' => {
				if (num) |n| {
					num = (n * num_letters) + (c - 'A');
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
		return NodeWithId{
			.id = nums[0],
			.node = Node{.last = last, .left = nums[1], .right = nums[2]}
		};
	}
};

const NodeWithId = struct {
	id: usize,
	node: Node,
};

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

	var args = std.process.args();
	_ = args.skip();

	var iterations: usize = 1;
	if (args.next()) |arg_iter| {
		iterations = try std.fmt.parseInt(usize, arg_iter, 10);
	}

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	const max_nodes = num_letters*num_letters*num_letters;
	var nodes: []Node = try allocator.alloc(Node, max_nodes);
	@memset(nodes, Node{.left = 0, .right = 0, .last = 0});
	defer allocator.free(nodes);

	const input = try allocator.alloc(u8, 50*(1<<10));
	defer allocator.free(input);
	const input_len = try stdin.readAll(input);

	var buffer = std.io.FixedBufferStream([]u8){.buffer = input[0..input_len], .pos = 0};

	var line_buf: []u8 = try allocator.alloc(u8, 1024);
	defer allocator.free(line_buf);


	for (0..iterations) |_| {
		buffer.reset();
		var in = buffer.reader();

		const path = try in.readUntilDelimiterOrEofAlloc(allocator, '\n', 2*(1<<20)) orelse return;
		defer allocator.free(path);
		_ = try in.readUntilDelimiterOrEof(line_buf, '\n');

		var ends_with_a = std.ArrayList(usize).init(allocator);
		defer ends_with_a.deinit();

		while (try in.readUntilDelimiterOrEof(line_buf, '\n')) |nline| {
			const n = Node.parse(nline) orelse continue;
			nodes[n.id] = n.node;
			if (n.node.last == 0) {
				try ends_with_a.append(n.id);
			}
		}

		{
			var s: usize = 0;
			var p: usize = Node.id_from_str("AAA");
			var dst: usize = Node.id_from_str("ZZZ");
			while (true) : (s += 1) {
				const step = path[s % path.len];
				const n = nodes[p];
				if (p == dst) {
					break;
				}
				p = switch (step) {
				'L' => n.left,
				'R' => n.right,
				else => unreachable, // TODO
				};
			}
			try stdout.print("{?}\n", .{s});
		}

		{
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
			try stdout.print("{?}\n", .{required_steps});
		}
	}
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

