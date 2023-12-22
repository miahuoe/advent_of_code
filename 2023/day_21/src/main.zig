const std = @import("std");

const Map = struct {
	const Self = @This();

	allocator: std.mem.Allocator,
	w: i64,
	h: i64,
	grid: std.ArrayList(u8),
	sx: i64,
	sy: i64,

	pub fn deinit(self: Self) void {
		self.grid.deinit();
	}

	pub fn init(allocator: std.mem.Allocator) Self {
		return Self{
			.allocator = allocator,
			.w = 0,
			.h = 0,
			.sx = 0,
			.sy = 0,
			.grid = std.ArrayList(u8).init(allocator),
		};
	}

	pub fn append_row(self: *Self, row: []u8) !void {
		var r = try self.grid.addManyAsSlice(row.len);
		@memcpy(r, row);
		for (r, 0..) |c, x| {
			if (c == 'S') {
				r[x] = '.';
				self.sx = @intCast(x);
				self.sy = self.h;
				break;
			}
		}
		self.w = @intCast(row.len);
		self.h += 1;
	}

	pub fn reach(self: *Self, start: @Vector(2, i64), steps: i64) !@Vector(2, i64) {
		var prev = try self.allocator.alloc(bool, self.grid.items.len);
		defer self.allocator.free(prev);

		var next = try self.allocator.alloc(bool, self.grid.items.len);
		defer self.allocator.free(next);

		@memset(prev, false);
		@memset(next, false);
		next[@intCast(start[1] * self.w + start[0])] = true;

		var s: i64 = 0;
		while (s < steps) : (s += 1) {
			@memcpy(prev, next);
			var y: i64 = 0;
			while (y < self.h) : (y += 1) {
				var x: i64 = 0;
				while (x < self.w) : (x += 1) {
					const idx: usize = @intCast(y * self.w + x);
					if (self.grid.items[idx] != '.') {
						continue;
					}
					if (prev[idx]) {
						continue;
					}
					var N = [4]@Vector(2, i64){
						@Vector(2, i64){-1, 0},
						@Vector(2, i64){1, 0},
						@Vector(2, i64){0, -1},
						@Vector(2, i64){0, 1},
					};
					var visited_neighbours: usize = 0;
					for (N) |n| {
						const X = x+n[0];
						const Y = y+n[1];
						if (X < 0 or X >= self.w or Y < 0 or Y >= self.h) {
							continue;
						}
						const nidx: usize = @intCast(Y * self.w + X);
						if (self.grid.items[nidx] != '.') {
							continue;
						}
						if (prev[nidx]) {
							visited_neighbours += 1;
						}
					}
					if (visited_neighbours > 0) {
						next[idx] = true;
					}
				}
			}
		}
		var eo = @Vector(2, i64){0, 0};
		var y: i64 = 0;
		while (y < self.h) : (y += 1) {
			var x: i64 = 0;
			while (x < self.w) : (x += 1) {
				if (!next[@intCast(y * self.w + x)]) {
					continue;
				}
				if (@rem(x + y, 2) == 0) {
					eo[0] += 1;
				} else {
					eo[1] += 1;
				}
			}
		}
		return eo;
	}

	pub fn reach_big(self: *Self, steps: i64) !i64 {
		std.debug.assert(self.w == self.h);
		// Operations hardcoded to fit my input

		const S: i64 = @intCast(steps);
		const W: i64 = @intCast(self.w); // grid [W]idth
		const M: i64 = @divTrunc(W, 2); // grid [M]iddle
		const r: i64 = @divTrunc(S, W); // diamond [r]adius
		const rem: i64 = @rem(S, W);

		const whole = try self.reach(.{M, M}, W);
		const rd = try self.reach(.{0, 0}, rem-1);
		const ru = try self.reach(.{0, W-1}, rem-1);
		const ld = try self.reach(.{W-1, 0}, rem-1);
		const lu = try self.reach(.{W-1, W-1}, rem-1);

		var re: i64 = 0;
		re += (r + 1) * (r + 1) * whole[1];
		re += r * r * whole[0];
		re -= (r + 1) * (rd[1] + ru[1] + ld[1] + lu[1]);
		re += r * (rd[0] + ru[0] + ld[0] + lu[0]);
		return re;

	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();
	defer _ = gpa.deinit();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var map = Map.init(allocator);
	defer map.deinit();
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		try map.append_row(line);
	}
	const part1 = try map.reach(.{map.sx, map.sy}, 64);
	try stdout.print("{d}\n", .{part1[0]});

	const part2 = try map.reach_big(26501365);
	try stdout.print("{d}\n", .{part2});
	// TODO outputs 620348632112622
}

