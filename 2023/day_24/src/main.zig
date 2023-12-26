const std = @import("std");

const IntersectionTag = enum {
	Parallel,
	Colinear,
	Cross,
	None,
};

const Intersection = union(IntersectionTag) {
	Parallel: void,
	Colinear: void,
	Cross: @Vector(2, f64),
	None: void,
};

const Hailstone = struct {
	const Self = @This();

	position: @Vector(3, i64),
	velocity: @Vector(3, i64),

	pub fn from_line(line: []u8) !?Self {
		var H: Hailstone = undefined;
		var it = std.mem.tokenizeSequence(u8, line, " @ ");
		const pos = it.next() orelse return null;
		const vel = it.next() orelse return null;
		var pos_it = std.mem.tokenizeSequence(u8, pos, ", ");
		var vel_it = std.mem.tokenizeSequence(u8, vel, ", ");
		for (0..3) |i| {
			const p = pos_it.next() orelse return null;
			const v = vel_it.next() orelse return null;
			H.position[i] = try std.fmt.parseInt(i64, p, 10);
			H.velocity[i] = try std.fmt.parseInt(i64, v, 10);
		}
		return H;
	}

	// Segment-segment intersection. Working on i64 as long as possible
	pub fn intersect(A: Self, B: Self) Intersection {
		const A_begin = A.position;
		const A_end = A.position + A.velocity;
		const B_begin = B.position;
		const B_end = B.position + B.velocity;
		const tu_den: i64 = (A_begin[0] - A_end[0]) * (B_begin[1] - B_end[1]) - (A_begin[1] - A_end[1]) * (B_begin[0] - B_end[0]);
		const t_num: i64 = (A_begin[0] - B_begin[0]) * (B_begin[1] - B_end[1]) - (A_begin[1] - B_begin[1]) * (B_begin[0] - B_end[0]);
		const u_num: i64 = (A_begin[0] - B_begin[0]) * (A_begin[1] - A_end[1]) - (A_begin[1] - B_begin[1]) * (A_begin[0] - A_end[0]);
		if (tu_den == 0) {
			if (t_num == 0 or u_num == 0) {
				return .Colinear;
			} else {
				return .Parallel;
			}
		}
		const t = @as(f64, @floatFromInt(t_num)) / @as(f64, @floatFromInt(tu_den));
		const u = @as(f64, @floatFromInt(u_num)) / @as(f64, @floatFromInt(tu_den));
		if (t >= 0 and u >= 0) {
			const T = @Vector(2, f64){t, t};
			const begin = @Vector(2, f64){@floatFromInt(A_begin[0]), @floatFromInt(A_begin[1])};
			const end = @Vector(2, f64){@floatFromInt(A_end[0]), @floatFromInt(A_end[1])};
			return Intersection{.Cross = begin + T * (end - begin)};
		}
		return .None;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();
	defer _ = gpa.deinit();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var hailstones = std.ArrayList(Hailstone).init(allocator);
	defer hailstones.deinit();

	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		const H = try Hailstone.from_line(line) orelse return;
		try hailstones.append(H);
	}
	var crossing_count: usize = 0;

	const test_area = @Vector(2, f64){200000000000000, 400000000000000};
	//const test_area = @Vector(2, f64){7, 27};
	for (hailstones.items, 0..) |ha, ai| {
		for (hailstones.items, 0..) |hb, bi| {
			if (ai >= bi) {
				continue;
			}
			const i = ha.intersect(hb);
			switch (i) {
			.Cross => |p| {
				if (test_area[0] <= p[0] and p[0] <= test_area[1] and test_area[0] <= p[1] and p[1] <= test_area[1]) {
					crossing_count += 1;
				}
			},
			.None, .Colinear, .Parallel => {},
			}
		}
	}

	try stdout.print("{d}\n", .{crossing_count});
}

