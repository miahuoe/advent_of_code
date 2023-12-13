const std = @import("std");

const Pattern = struct {
	allocator: std.mem.Allocator,
	w: usize,
	h: usize,
	grid: std.ArrayList(u8),

	pub fn init(allocator: std.mem.Allocator) Pattern {
		return Pattern{
			.allocator = allocator,
			.w = 0,
			.h = 0,
			.grid = std.ArrayList(u8).init(allocator),
		};
	}

	pub fn at(self: *const Pattern, x: usize, y: usize) u8 {
		return self.grid.items[y*self.w+x];
	}

	pub fn cols_cmp(self: *const Pattern, ax: usize, bx: usize) usize {
		var s: usize = 0;
		for (0..self.h) |y| {
			if (self.at(ax, y) == self.at(bx, y)) {
				s += 1;
			}
		}
		return s;
	}

	pub fn find_reflection_vertical(self: *const Pattern, smudges: usize) ?usize {
		row: for (0..self.w-1) |x| {
			var i: usize = 0;
			var s: usize = 0;
			while (i <= x and x+1+i < self.w) : (i += 1) {
				const H = self.cols_cmp(x-i, x+1+i);
				s += self.h - H;
				if (s > smudges) {
					continue :row;
				}
			}
			if (s == smudges) {
				return x;
			}
		}
		return null;
	}

	pub fn rows_cmp(self: *const Pattern, ay: usize, by: usize) usize {
		var c: usize = 0;
		for (0..self.w) |x| {
			if (self.at(x, ay) == self.at(x, by)) {
				c += 1;
			}
		}
		return c;
	}

	pub fn find_reflection_horizontal(self: *const Pattern, smudges: usize) ?usize {
		col: for (0..self.h-1) |y| {
			var i: usize = 0;
			var s: usize = 0;
			while (i <= y and y+1+i < self.h) : (i += 1) {
				const W = self.rows_cmp(y-i, y+1+i);
				s += self.w - W;
				if (s > smudges) {
					continue :col;
				}
			}
			if (s == smudges) {
				return y;
			}
		}
		return null;
	}

	pub fn append_row(self: *Pattern, row: []u8) !void {
		var r = try self.grid.addManyAsSlice(row.len);
		@memcpy(r, row);
		self.w = row.len;
		self.h += 1;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var patterns = std.ArrayList(Pattern).init(allocator);
	try patterns.append(Pattern.init(allocator));
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		if (line.len == 0) {
			try patterns.append(Pattern.init(allocator));
		} else {
			try patterns.items[patterns.items.len-1].append_row(line);
		}
	}
	var part1: usize = 0;
	var part2: usize = 0;
	for (patterns.items) |p| {
		for (0..p.h) |y| {
			for (0..p.w) |x| {
				try stdout.print("{c}", .{p.at(x, y)});
			}
			try stdout.print("\n", .{});
		}
		if (p.find_reflection_vertical(0)) |v| {
			part1 += v+1;
			try stdout.print(" v:{d}", .{v+1});
		}
		if (p.find_reflection_horizontal(0)) |h| {
			part1 += (h+1)*100;
			try stdout.print(" h:{d}", .{h+1});
		}
		if (p.find_reflection_vertical(1)) |v2| {
			part2 += v2+1;
			try stdout.print(" V:{d}", .{v2+1});
		}
		if (p.find_reflection_horizontal(1)) |h2| {
			part2 += (h2+1)*100;
			try stdout.print(" H:{d}", .{h2+1});
		}
		try stdout.print("\n", .{});
		try stdout.print("\n", .{});
	}
	try stdout.print("{d} {d}\n", .{part1, part2});
}

