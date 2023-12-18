const std = @import("std");

const Direction = enum {
	Right,
	Left,
	Up,
	Down,
};

const Wall = struct {
	x: i64,
	y1: i64,
	y2: i64,

	pub fn cmp(ctx: void, a: Wall, b: Wall) bool {
		return std.sort.asc(i64)(ctx, a.x, b.x);
	}
};

const PlanItem = struct {
	direction: Direction,
	length: i64,
	color: [3]u8,

	pub fn part1_from(line: []u8) !?PlanItem {
		var pi: PlanItem = undefined;
		var it = std.mem.tokenizeAny(u8, line, " ");
		var direction = it.next() orelse return null;
		pi.direction = switch (direction[0]) {
			'U' => .Up,
			'D' => .Down,
			'R' => .Right,
			'L' => .Left,
			else => return null,
		};
		var length = it.next() orelse return null;
		pi.length = try std.fmt.parseInt(i64, length, 10);
		return pi;
	}

	pub fn part2_from(line: []u8) !?PlanItem {
		var pi: PlanItem = undefined;
		var it = std.mem.tokenizeAny(u8, line, " ");
		_ = it.next() orelse return null;
		_ = it.next() orelse return null;
		var color = it.next() orelse return null;
		pi.length = try std.fmt.parseInt(i64, color[2..7], 16);
		pi.direction = switch (color[7]) {
			'0' => .Right,
			'1' => .Down,
			'2' => .Left,
			'3' => .Up,
			else => return null,
		};
		return pi;
	}
};

pub fn walls_from_plan(plan: *const std.ArrayList(PlanItem), allocator: std.mem.Allocator) !std.ArrayList(Wall) {
	var walls = std.ArrayList(Wall).init(allocator);

	var px: i64 = 0;
	var py: i64 = 0;
	for (plan.items) |pi| {
		switch (pi.direction) {
			.Right => {
				px += pi.length;
			},
			.Left => {
				px -= pi.length;
			},
			.Up => {
				var wall = Wall{.x = px, .y1 = py - pi.length, .y2 = py};
				try walls.append(wall);
				py -= pi.length;
			},
			.Down => {
				var wall = Wall{.x = px, .y1 = py, .y2 = py + pi.length};
				try walls.append(wall);
				py += pi.length;
			},
		}
	}
	std.sort.insertion(Wall, walls.items, {}, Wall.cmp);
	return walls;
}

const Span = struct {
	a: i64,
	b: i64,

	pub fn cmp(_: void, X: Span, Y: Span) bool {
		if (X.a == Y.a) {
			return X.b < Y.b;
		}
		return X.a < Y.a;
	}
};

pub fn get_area(plan: *const std.ArrayList(PlanItem), allocator: std.mem.Allocator) !i64 {
	var walls = try walls_from_plan(plan, allocator);
	defer walls.deinit();

	var total_area: i64 = 0;
	var x: i64 = walls.items[0].x;
	var nx: i64 = 0;
	var wi: usize = 0;
	var spans = std.ArrayList(Span).init(allocator);
	defer spans.deinit();
	while (wi < walls.items.len) {
		var area_before: i64 = 0;
		for (spans.items) |s| {
			area_before += s.b - s.a + 1;
		}
		while (wi < walls.items.len) : (wi += 1) {
			const w = walls.items[wi];
			if (w.x != x) {
				nx = w.x;
				break;
			}
			const N = Span{.a = w.y1, .b = w.y2};
			var i: usize = 0;
			var found = false;
			while (i < spans.items.len) : (i += 1) {
				var O = &spans.items[i];
				if (O.a == N.a) {
					O.a = N.b;
					found = true;
					break;
				}
				if (O.b == N.b) {
					O.b = N.a;
					found = true;
					break;
				}
				if (O.b == N.a) {
					O.b = N.b;
					found = true;
					break;
				}
				if (O.a == N.b) {
					O.a = N.a;
					found = true;
					break;
				}
				if (O.a < N.a and N.b < O.b) { // split
					try spans.append(.{.a = N.b, .b = O.b});
					O.b = N.a;
					found = true;
					break;
				}
			}
			if (!found) {
				try spans.append(N);
			}
			i = 0;
			while (i < spans.items.len) {
				var s = &spans.items[i];
				if (s.a == s.b) {
					_ = spans.orderedRemove(i);
					continue;
				}
				i += 1;
			}
			std.sort.insertion(Span, spans.items, {}, Span.cmp);
			i = 1;
			while (i < spans.items.len) {
				var s1 = &spans.items[i-1];
				var s2 = &spans.items[i];
				if (s1.b == s2.a) {
					s1.b = s2.b;
					_ = spans.orderedRemove(i);
					continue;
				}
				i += 1;
			}
		}
		var area_after: i64 = 0;
		for (spans.items) |s| {
			area_after += s.b - s.a + 1;
		}
		const dx = nx - x;
		total_area += @max(area_before, area_after);
		total_area += (dx-1)*area_after;
		x = nx;
	}
	return total_area;
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var plan1 = std.ArrayList(PlanItem).init(allocator);
	defer plan1.deinit();

	var plan2 = std.ArrayList(PlanItem).init(allocator);
	defer plan2.deinit();

	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		var p1 = try PlanItem.part1_from(line) orelse continue;
		try plan1.append(p1);
		var p2 = try PlanItem.part2_from(line) orelse continue;
		try plan2.append(p2);
	}
	// TODO after optimization:
	// for input: part2 works but part1 is broken (for my input)
	// for example: both parts work
	const part1 = try get_area(&plan1, allocator);
	try stdout.print("{d}\n", .{part1});
	const part2 = try get_area(&plan2, allocator);
	try stdout.print("{d}\n", .{part2});
}

