const std = @import("std");

const Galaxy = struct {
	x: usize,
	y: usize,

	fn sort_by_x(context: void, a: Galaxy, b: Galaxy) bool {
		return std.sort.asc(usize)(context, a.x, b.x);
	}

	fn sort_by_y(context: void, a: Galaxy, b: Galaxy) bool {
		return std.sort.asc(usize)(context, a.y, b.y);
	}

	fn distance_to(self: Galaxy, other: Galaxy) usize {
		var ax: i64 = @as(i64, @intCast(self.x));
		var ay: i64 = @as(i64, @intCast(self.y));

		var bx: i64 = @as(i64, @intCast(other.x));
		var by: i64 = @as(i64, @intCast(other.y));

		return @abs(bx - ax) + @abs(by - ay);
	}
};

const Map = struct {
	w: usize,
	h: usize,
	cells_len: usize,
	cells: []u8,
	galaxies_count: usize,
	galaxies: []Galaxy,

	pub fn expand(self: *Map, factor: usize) void {
		std.sort.insertion(Galaxy, self.galaxies[0..self.galaxies_count], {}, Galaxy.sort_by_x);
		for (0..self.galaxies_count-1) |gi| {
			const diff = self.galaxies[gi+1].x - self.galaxies[gi].x;
			if (diff <= 1) {
				continue;
			}
			for (gi+1..self.galaxies_count) |gj| {
				self.galaxies[gj].x += (diff-1)*@max(1, factor-1);
			}
		}
		std.sort.insertion(Galaxy, self.galaxies[0..self.galaxies_count], {}, Galaxy.sort_by_y);
		for (0..self.galaxies_count-1) |gi| {
			const diff = self.galaxies[gi+1].y - self.galaxies[gi].y;
			if (diff <= 1) {
				continue;
			}
			for (gi+1..self.galaxies_count) |gj| {
				self.galaxies[gj].y += (diff-1)*@max(1, factor-1);
			}
		}
	}

	pub fn prepare(self: *Map) void {
		self.w = 0;
		self.h = 0;
		self.galaxies_count = 0;
		var x: usize = 0;
		for (0..self.cells_len) |i| {
			const c = self.cells[i];
			if (c == '\n') {
				x = 0;
				self.h += 1;
			} else {
				if (c == '#') {
					self.galaxies[self.galaxies_count].x = x;
					self.galaxies[self.galaxies_count].y = self.h;
					self.galaxies_count += 1;
				}
				if (self.h == 0) {
					self.w += 1;
				}
				x += 1;
			}
		}
		if (x > 0) {
			self.h += 1;
		}
	}

	pub fn distance_sum(self: *Map) usize {
		var distance: usize = 0;
		for (0..self.galaxies_count) |i| {
			for (0..self.galaxies_count) |j| {
				if (j >= i) {
					continue;
				}
				distance += self.galaxies[i].distance_to(self.galaxies[j]);
			}
		}
		return distance;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var map: Map = undefined;

	map.cells = try allocator.alloc(u8, 1<<20);
	defer allocator.free(map.cells);

	map.galaxies = try allocator.alloc(Galaxy, 1000);
	defer allocator.free(map.galaxies);

	map.cells_len = try stdin.readAll(map.cells);

	map.prepare();
	map.expand(2);
	const distance_sum_1 = map.distance_sum();

	map.prepare();
	map.expand(1000000);
	const distance_sum_2 = map.distance_sum();

	try stdout.print("{d}\n{d}\n", .{distance_sum_1, distance_sum_2});
}

test "distance" {
	const a = Galaxy{.x = 0, .y = 0};
	const b = Galaxy{.x = 4, .y = 5};
	try std.testing.expectEqual(a.distance_to(b), 9);
	try std.testing.expectEqual(b.distance_to(a), 9);
}

