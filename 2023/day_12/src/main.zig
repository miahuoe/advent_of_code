const std = @import("std");

const SpringArray = struct {
	blocks_count: usize,
	blocks: [64]usize,
	springs_count: usize,
	springs: [64]u8,

	stack: [64]u8,
	H: std.AutoHashMap(usize, usize),

	pub fn from_line(line: []u8) SpringArray {
		var sa: SpringArray = undefined;
		sa.springs_count = 0;
		sa.blocks_count = 0;
		var i: usize = 0;
		while (i < line.len) : (i += 1) {
			const c = line[i];
			switch (c) {
			'#','.','?' => {
				sa.springs[sa.springs_count] = c;
				sa.springs_count += 1;
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
					sa.blocks[sa.blocks_count] = n;
					sa.blocks_count += 1;
					num = null;
				}
			},
			else => unreachable,
			}
		}
		if (num) |n| {
			sa.blocks[sa.blocks_count] = n;
			sa.blocks_count += 1;
		}
		return sa;
	}

	pub fn analyze(self: *SpringArray) !usize {
		self.H.clearRetainingCapacity();
		return try self._analyze('.', 0, 0, 0);
	}

	pub fn _analyze(self: *SpringArray, prev: u8, i: usize, bi: usize, count: usize) !usize {
		const key = count*self.blocks_count*self.springs_count + bi*self.springs_count + i;
		var cached = self.H.get(key);
		if (cached) |c| {
			_ = c;
			//return c;
		}
		self.stack[i] = prev;
		if (i == self.springs_count) {
			//std.log.debug("[{s}] ({d}/{d} {d}/{d})", .{self.stack[1..1+i], bi, self.blocks_count, count, self.blocks[bi]});
			if ((bi == self.blocks_count and count == 0) or (bi == self.blocks_count-1 and count == self.blocks[bi])) {
				//std.log.debug("[{s}] {any}", .{self.stack[1..1+i], self.blocks[0..self.blocks_count]});
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
			c += try self._analyze('#', i+1, bi, count+1);
		}
		try self.H.put(key, c);
		return c;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;
	var sum: usize = 0;
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		if (line.len == 0) {
			continue;
		}
		var springs = SpringArray.from_line(line);
		for (0..springs.springs_count) |s| {
			try stdout.print("{c}", .{springs.springs[s]});
		}
		for (0..springs.blocks_count) |b| {
			try stdout.print(" {d}", .{springs.blocks[b]});
		}
		springs.H = std.AutoHashMap(usize, usize).init(allocator);
		defer springs.H.deinit();
		const ar = try springs.analyze();
		sum += ar;
		try stdout.print(" -> {d}\n", .{ar});
	}
	try stdout.print("{d}\n", .{sum});
}

