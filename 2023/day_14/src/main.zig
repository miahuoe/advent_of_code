const std = @import("std");

const Platform = struct {
	const Self = @This();

	allocator: std.mem.Allocator,
	w: usize,
	h: usize,
	grid: std.ArrayList(u8),

	pub fn init(allocator: std.mem.Allocator) Self {
		return Self{
			.allocator = allocator,
			.w = 0,
			.h = 0,
			.grid = std.ArrayList(u8).init(allocator),
		};
	}

	pub fn append_row(self: *Self, row: []u8) !void {
		var r = try self.grid.addManyAsSlice(row.len);
		@memcpy(r, row);
		self.w = row.len;
		self.h += 1;
	}

	pub fn at(self: *const Self, x: usize, y: usize) u8 {
		return self.grid.items[y*self.w+x];
	}

	pub fn tilt(self: *const Self) usize {
		var weight: usize = 0;
		for (0..self.w) |x| {
			var W: usize = self.h;
			for (0..self.h) |y| {
				switch (self.grid.items[y*self.w+x]) {
				'O' => {
					weight += W;
					W -= 1;
				},
				'.' => {
				},
				'#' => {
					W = self.h-1-y;
				},
				else => {},
				}
			}
		}
		return weight;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var platform = Platform.init(allocator);
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		try platform.append_row(line);
	}
	for (0..platform.h) |y| {
		for (0..platform.w) |x| {
			try stdout.print("{c}", .{platform.at(x, y)});
		}
		try stdout.print("\n", .{});
	}
	const weight = platform.tilt();
	try stdout.print("{d}\n", .{weight});
}

