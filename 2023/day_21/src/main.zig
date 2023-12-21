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
		for (row, 0..) |c, x| {
			if (c == 'S') {
				self.sx = @intCast(x);
				self.sy = self.h;
				r[x] = '.';
				break;
			}
		}
		self.w = @intCast(row.len);
		self.h += 1;
	}

	pub fn calculate_reachability(self: *Self, steps: usize) !usize {
		const initial = [4]usize{
			@intCast((self.sy+0) * self.w + (self.sx+1)),
			@intCast((self.sy+0) * self.w + (self.sx-1)),
			@intCast((self.sy+1) * self.w + (self.sx+0)),
			@intCast((self.sy-1) * self.w + (self.sx+0)),
		};
		var reachability = try self.allocator.alloc(u64, self.grid.items.len);
		defer self.allocator.free(reachability);
		@memset(reachability, 0);
		for (initial) |i| {
			if (self.grid.items[i] == '.') {
				reachability[i] |= 1;
			}
		}
		for (1..steps) |step| {
			var y: i64 = 0;
			while (y < self.h) : (y += 1) {
				var x: i64 = 0;
				while (x < self.w) : (x += 1) {
					const idx: usize = @intCast(y * self.w + x);
					if (self.grid.items[idx] != '.') {
						continue;
					}
					var neighbours_reachable_in_prev_step: usize = 0;
					var N = [4]@Vector(2, i64){
						@Vector(2, i64){-1, 0},
						@Vector(2, i64){1, 0},
						@Vector(2, i64){0, -1},
						@Vector(2, i64){0, 1},
					};
					for (N) |n| {
						if (x+n[0] < 0 or x+n[0] >= self.w or y+n[1] < 0 or y+n[1] >= self.h) {
							continue;
						}
						const nidx: usize = @intCast((y+n[1]) * self.w + (x+n[0]));
						const tile = self.grid.items[nidx];
						if (tile != '.') {
							continue;
						}
						const reach = reachability[nidx];
						const mask: usize = @shlExact(@as(u64, 1), @intCast(step-1));
						if (0 != (reach & mask)) {
							neighbours_reachable_in_prev_step += 1;
						}
					}
					if (neighbours_reachable_in_prev_step > 0) {
						const mask: usize = @shlExact(@as(u64, 1), @intCast(step));
						reachability[idx] |= mask;
					}
				}
			}
		}
		var c: usize = 0;
		const mask: usize = @shlExact(@as(usize, 1), @intCast(steps-1));
		for (reachability) |r| {
			if (0 != (r & mask)) {
				c += 1;
			}
		}
		return c;
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
	const part1 = try map.calculate_reachability(64);
	try stdout.print("{d}\n", .{part1});
}

