const std = @import("std");

const SpringArray = struct {
	blocks_count: usize,
	blocks: [64]usize,
	springs_count: usize,
	springs: [64]u8,

	arrangements: usize,
	stack: [64]u8,

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
					num = (n * 1) + (c - '0');
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

	pub fn analyze(self: *SpringArray) usize {
		self.arrangements = 0;
		self._analyze('.', 0, -1, 0);
		return self.arrangements;
	}

	pub fn _analyze(self: *SpringArray, prev: u8, si: usize, bi: i64, b_rem: usize) void {
		self.stack[si] = prev;
		if (si == self.springs_count) {
			if (b_rem == 0 and bi == self.blocks_count-1) {
				std.log.debug("[{s}]", .{self.stack[1..1+si]});
				self.arrangements += 1;
			}
			return;
		}
		const curr = self.springs[si];
		switch (prev) {
		else => {},
		'.' => {
			switch (curr) {
			else => {},
			'?' => {
				if (bi+1 < self.blocks_count) {
					self._analyze('#', si+1, bi+1, self.blocks[@intCast(bi+1)]-1);
				}
				if (b_rem == 0) {
					self._analyze('.', si+1, bi, b_rem);
				}
			},
			'.' => {
				if (b_rem == 0) {
					self._analyze('.', si+1, bi, b_rem);
				}
			},
			'#' => {
				if (bi+1 < self.blocks_count and b_rem == 0) {
					self._analyze('#', si+1, bi+1, self.blocks[@intCast(bi+1)]-1);
				}
			},
			}
		},
		'#' => {
			switch (curr) {
			else => {},
			'?' => {
				if (b_rem == 0) {
					self._analyze('.', si+1, bi, b_rem);
				} else {
					self._analyze('#', si+1, bi, b_rem-1);
				}
			},
			'.' => {
				if (b_rem == 0) {
					self._analyze('.', si+1, bi, b_rem);
				}
			},
			'#' => {
				if (b_rem > 0) {
					self._analyze('#', si+1, bi, b_rem-1);
				}
			},
			}
		},
		}
	}
};

pub fn main() !void {
	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;
	var sum: usize = 0;
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		if (line.len == 0) {
			continue;
		}
		var springs = SpringArray.from_line(line);
		try stdout.print("       [", .{});
		for (0..springs.springs_count) |s| {
			try stdout.print("{c}", .{springs.springs[s]});
		}
		try stdout.print("] ", .{});
		for (0..springs.blocks_count) |b| {
			try stdout.print(" {d}", .{springs.blocks[b]});
		}
		try stdout.print("\n", .{});
		const ar = springs.analyze();
		sum += ar;
		try stdout.print("{d}\n\n", .{ar});
	}
	try stdout.print("{d}\n", .{sum});
}

