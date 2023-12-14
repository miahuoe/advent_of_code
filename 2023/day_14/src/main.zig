const std = @import("std");

const Platform = struct {
	const Self = @This();

	allocator: std.mem.Allocator,
	w: usize,
	h: usize,
	grid: std.ArrayList(u8),

	pub fn deinit(self: Self) void {
		self.grid.deinit();
	}

	pub fn init(allocator: std.mem.Allocator) Self {
		return Self{
			.allocator = allocator,
			.w = 0,
			.h = 0,
			.grid = std.ArrayList(u8).init(allocator),
		};
	}

	pub fn clone(self: *Self) !Self {
		var c = Self{
			.allocator = self.allocator,
			.w = self.w,
			.h = self.h,
			.grid = std.ArrayList(u8).init(self.allocator),
		};
		var all = try c.grid.addManyAsSlice(self.grid.items.len);
		@memcpy(all, self.grid.items);
		return c;
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

	pub fn get_weight(self: *const Self) usize {
		var we: usize = 0;
		for (0..self.w) |x| {
			for (0..self.h) |y| {
				if (self.grid.items[y*self.w+x] == 'O') {
					we += self.h-y;
				}
			}
		}
		return we;
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

	pub fn tilt_north(self: *Self) void {
		for (0..self.w) |x| {
			var Y: usize = 0;
			for (0..self.h) |y| {
				switch (self.grid.items[y*self.w+x]) {
				'O' => {
					self.grid.items[y*self.w+x] = '.';
					self.grid.items[Y*self.w+x] = 'O';
					Y += 1;
				},
				'#' => {
					Y = y+1;
				},
				else => {},
				}
			}
		}
	}

	pub fn tilt_south(self: *Self) void {
		for (0..self.w) |x| {
			var Y: usize = self.h-1;
			for (0..self.h) |y| {
				const yy = self.h-1-y;
				switch (self.grid.items[yy*self.w+x]) {
				'O' => {
					self.grid.items[yy*self.w+x] = '.';
					self.grid.items[Y*self.w+x] = 'O';
					if (Y > 0) {
						Y -= 1;
					}
				},
				'#' => {
					if (yy > 0) {
						Y = yy-1;
					}
				},
				else => {},
				}
			}
		}
	}

	pub fn tilt_west(self: *Self) void {
		for (0..self.h) |y| {
			var X: usize = 0;
			for (0..self.w) |x| {
				switch (self.grid.items[y*self.w+x]) {
				'O' => {
					self.grid.items[y*self.w+x] = '.';
					self.grid.items[y*self.w+X] = 'O';
					X += 1;
				},
				'#' => {
					X = x+1;
				},
				else => {},
				}
			}
		}
	}

	pub fn tilt_east(self: *Self) void {
		for (0..self.h) |y| {
			var X: usize = self.w-1;
			for (0..self.w) |x| {
				const xx = self.w-1-x;
				switch (self.grid.items[y*self.w+xx]) {
				'O' => {
					self.grid.items[y*self.w+xx] = '.';
					self.grid.items[y*self.w+X] = 'O';
					if (X > 0) {
						X -= 1;
					}
				},
				'#' => {
					if (xx > 0) {
						X = xx-1;
					}
				},
				else => {},
				}
			}
		}
	}

	pub fn cycle(self: *Self) void {
		self.tilt_north();
		self.tilt_west();
		self.tilt_south();
		self.tilt_east();
	}

	pub fn eql(self: Self, other: Self) bool {
		return std.mem.eql(u8, self.grid.items, other.grid.items);
	}

	pub fn spin(self: *Self, count: usize) !usize {
		var t = try self.clone();
		var h = try self.clone();

		t.cycle();
		h.cycle();
		h.cycle();
		while (!t.eql(h)) {
			t.cycle();
			h.cycle();
			h.cycle();
		}
		t.deinit();

		t = try self.clone();
		var s: usize = 0;
		while (!t.eql(h)) {
			t.cycle();
			h.cycle();
			s += 1;
		}
		h.deinit();

		h = try t.clone();
		h.cycle();
		var ll: usize = 1;
		while (!t.eql(h)) {
			h.cycle();
			ll += 1;
		}
		h.deinit();
		t.deinit();

		const cc = s + ((count - s) % ll);
		for (0..cc) |_| {
			self.cycle();
		}
		return self.get_weight();
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
	const part1 = platform.tilt();
	const part2 = try platform.spin(1000000000);
	try stdout.print("{d}\n{d}\n", .{part1, part2});
}

