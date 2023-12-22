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

	pub fn reach(self: *Self, start: @Vector(2, i64), steps: i64) !@Vector(4, i64) {
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
		var eo = @Vector(4, i64){0, 0, 0, 0};
		// [0] = reachable even
		// [1] = reachable odd
		// [2] = unreachable even
		// [3] = unreachable odd
		var y: i64 = 0;
		while (y < self.h) : (y += 1) {
			var x: i64 = 0;
			while (x < self.w) : (x += 1) {
				const idx: usize = @intCast(y * self.w + x);
				if (self.grid.items[idx] != '.') {
					continue;
				}
				if (next[idx]) {
					if (@rem(x + y, 2) == 0) {
						eo[0] += 1;
					} else {
						eo[1] += 1;
					}
				} else {
					if (@rem(x + y, 2) == 0) {
						eo[2] += 1;
					} else {
						eo[3] += 1;
					}
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
		const R = @Vector(2, i64){0, M};
		const L = @Vector(2, i64){W-1, M};
		const U = @Vector(2, i64){M, W-1};
		const D = @Vector(2, i64){M, 0};
		const rd = @Vector(2, i64){0, 0};
		const ru = @Vector(2, i64){0, W-1};
		const ld = @Vector(2, i64){W-1, 0};
		const lu = @Vector(2, i64){W-1, W-1};
		const e: usize = 0; // TODO swap e and o depending on oddness of farthest grid
		const o: usize = 1;

		const whole = try self.reach(.{M, M}, W);

		var whole_o: i64 = (r - 1) * (r - 1) * whole[o];
		var whole_e: i64 = r * r * whole[e];

		var corners: i64 = (0
			+ (try self.reach(R, W-1))[o]
			+ (try self.reach(L, W-1))[o]
			+ (try self.reach(U, W-1))[o]
			+ (try self.reach(D, W-1))[o]
		);

		var small_partial: i64 = r * (0
			+ (try self.reach(rd, rem-1))[e]
			+ (try self.reach(ru, rem-1))[e]
			+ (try self.reach(ld, rem-1))[e]
			+ (try self.reach(lu, rem-1))[e]
		);
		var big_partial: i64 = (r - 1) * (0
			+ (try self.reach(rd, W+rem))[o]
			+ (try self.reach(ru, W+rem))[o]
			+ (try self.reach(ld, W+rem))[o]
			+ (try self.reach(lu, W+rem))[o]
		);

		return corners + whole_o + whole_e + big_partial + small_partial;

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
}

