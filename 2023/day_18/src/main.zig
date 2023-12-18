const std = @import("std");

const Direction = enum {
	Right,
	Left,
	Up,
	Down,
};

const Wall = struct {
	y: i64,
	x1: i64,
	x2: i64,

	pub fn cmp(ctx: void, a: Wall, b: Wall) bool {
		return std.sort.asc(i64)(ctx, a.y, b.y);
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

pub fn get_area(plan: *const std.ArrayList(PlanItem)) !i64 {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var walls = std.ArrayList(Wall).init(allocator);
	defer walls.deinit();

	var px: i64 = 0;
	var py: i64 = 0;
	for (plan.items) |pi| {
		switch (pi.direction) {
			.Right => {
				var wall = Wall{.y = py, .x1 = px, .x2 = px + pi.length};
				px += pi.length;
				try walls.append(wall);
			},
			.Left => {
				var wall = Wall{.y = py, .x1 = px - pi.length, .x2 = px};
				px -= pi.length;
				try walls.append(wall);
			},
			.Up => {
				py -= pi.length;
			},
			.Down => {
				py += pi.length;
			},
		}
	}
	std.sort.insertion(Wall, walls.items, {}, Wall.cmp);

	var x_min: i64 = 10000000;
	var x_max: i64 = -10000000;
	for (walls.items) |w| {
		x_min = @min(x_min, w.x1);
		x_max = @max(x_max, w.x2);
	}
	var y_min: i64 = walls.items[0].y;
	//var y_max: i64 = walls.items[walls.items.len-1].y;
	const width: usize = @intCast(x_max-x_min+1);

	var total_area: i64 = 0;
	var scanline = try allocator.alloc(u8, 100000000);
	defer allocator.free(scanline);
	@memset(scanline, '.');

	var wi: usize = 0;
	var y: i64 = y_min;
	while (wi < walls.items.len) {
		while (wi < walls.items.len) : (wi += 1) {
			const w = walls.items[wi];
			if (w.y != y) {
				break;
			}
			var i = w.x1 - x_min;
			while (i <= w.x2 - x_min) : (i += 1) {
				const j: usize = @intCast(i);
				const val = scanline[j];
				if (val == '#') {
					scanline[j] = 'X';
				} else if (val == '.') {
					scanline[j] = '@';
				}
			}
			var idx2: usize = @intCast(w.x2 - x_min);
			if (idx2+1 < width) {
				if (scanline[idx2+1] == '#') {
					scanline[idx2] = '#';
				}
			}
			var idx1: usize = @intCast(w.x1 - x_min);
			if (idx1 > 0) {
				if (scanline[idx1-1] == '#') {
					scanline[idx1] = '#';
				}
			}
		}
		var c: i64 = 0;
		for (0..width) |si| {
			if (scanline[si] != '.') {
				c += 1;
			}
		}
		for (0..width) |si| {
			if (scanline[si] == '@') {
				scanline[si] = '#';
			} else if (scanline[si] == 'X') {
				scanline[si] = '.';
			}
		}
		total_area += c;
		y += 1;
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
	const part1 = try get_area(&plan1);
	try stdout.print("{d}\n", .{part1});
	const part2 = try get_area(&plan2);
	try stdout.print("{d}\n", .{part2});
}

