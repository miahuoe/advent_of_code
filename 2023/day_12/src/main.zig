const std = @import("std");

const size = 1000;
const SpringArray = struct {
	blocks_count: usize,
	blocks: [size]usize,
	springs_count: usize,
	springs: [size]u8,
	biggest_block: usize,

	stack: [size]u8,
	cache: []?usize,

	pub fn from_line(line: []u8) SpringArray {
		var self: SpringArray = undefined;
		self.springs_count = 0;
		self.blocks_count = 0;
		var i: usize = 0;
		while (i < line.len) : (i += 1) {
			const c = line[i];
			switch (c) {
			'#','.','?' => {
				self.springs[self.springs_count] = c;
				self.springs_count += 1;
			},
			' ' => {
				i += 1;
				break;
			},
			else => unreachable,
			}
		}
		var num: ?usize = null;
		while (i < line.len) : (i += 1) {
			const c = line[i];
			switch (c) {
			'0'...'9' => {
				if (num) |n| {
					num = (n * 10) + (c - '0');
				} else {
					num = (c - '0');
				}
			},
			',' => {
				if (num) |n| {
					self.blocks[self.blocks_count] = n;
					self.blocks_count += 1;
					num = null;
				}
			},
			else => unreachable,
			}
		}
		if (num) |n| {
			self.blocks[self.blocks_count] = n;
			self.blocks_count += 1;
		}
		self.biggest_block = 0;
		for (0..self.blocks_count) |j| {
			self.biggest_block = @max(self.biggest_block, self.blocks[j]);
		}
		return self;
	}

	pub fn unfold(self: *SpringArray) void {
		self.springs[self.springs_count] = '?';
		self.springs_count += 1;
		for (1..5) |j| {
			for (0..self.springs_count) |i| {
				self.springs[i + j*self.springs_count] = self.springs[i];
			}
			for (0..self.blocks_count) |i| {
				self.blocks[i + j*self.blocks_count] = self.blocks[i];
			}
		}
		self.springs_count *= 5;
		self.springs_count -= 1;
		self.blocks_count *= 5;
		for (0..self.blocks_count) |j| {
			self.biggest_block = @max(self.biggest_block, self.blocks[j]);
		}
	}

	pub fn analyze(self: *SpringArray) !usize {
		return try self._analyze('.', 0, 0, 0);
	}

	pub fn _analyze(self: *SpringArray, prev: u8, i: usize, bi: usize, count: usize) !usize {
		const key = count*(self.blocks_count+1)*(self.springs_count+1) + i*(self.blocks_count+1) + bi;
		const cache = self.cache[key];
		if (cache) |c| {
			return c;
		}
		self.stack[i] = prev;
		if (i == self.springs_count) {
			if ((bi == self.blocks_count and count == 0) or (bi == self.blocks_count-1 and count == self.blocks[bi])) {
				return 1;
			}
			return 0;
		}
		var c: usize = 0;
		const curr = self.springs[i];
		if (curr == '?' or curr == '.') {
			if (count == 0) {
				c += try self._analyze('.', i+1, bi, 0);
			} else if (bi < self.blocks_count and count == self.blocks[bi]) {
				c += try self._analyze('.', i+1, bi+1, 0);
			}
		}
		if (curr == '?' or curr == '#') {
			if (count < self.blocks[bi]) {
				c += try self._analyze('#', i+1, bi, count+1);
			}
		}
		self.cache[key] = c;
		return c;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;
	var part1: usize = 0;
	var part2: usize = 0;
	var cache = try allocator.alloc(?usize, 1<<20);
	defer allocator.free(cache);
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		if (line.len == 0) {
			continue;
		}
		var springs = SpringArray.from_line(line);
		springs.cache = cache;
		@memset(springs.cache, null);

		part1 += try springs.analyze();

		springs.unfold();

		springs.cache = cache;
		@memset(springs.cache, null);

		part2 += try springs.analyze();
	}
	try stdout.print("{d}\n{d}\n", .{part1, part2});
}

