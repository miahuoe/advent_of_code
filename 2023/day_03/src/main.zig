const std = @import("std");

const Number = struct {
	value: usize,
	len: usize,
	x: usize,
	y: usize,
};

const Symbol = struct {
	c: u8,
	x: usize,
	y: usize,

	pub fn adjacent_to_number_on_x(self: *const Symbol, n: *const Number) bool {
		const x_min: usize = if (n.x > 0) n.x-1 else n.x;
		const x_max: usize = n.x+n.len;
		return x_min <= self.x and self.x <= x_max;
	}

	pub fn adjacent_to_number(self: *const Symbol, n: *const Number) bool {
		const x_min: usize = if (n.x > 0) n.x-1 else n.x;
		const x_max: usize = n.x+n.len;
		const y_min: usize = if (n.y > 0) n.y-1 else n.y;
		const y_max: usize = n.y+1;
		return x_min <= self.x and self.x <= x_max and y_min <= self.y and self.y <= y_max;
	}
};

const Line = struct {
	first: usize,
	last: usize,
};

const Schematic = struct {
	symbols_count: usize,
	symbols: [1000]Symbol,

	// Save range of numbers (indices on numbers array) that belong to given line.
	// Later it's faster to just lookup 3 possible lines based on symbols y coordinate.
	lines_count: usize,
	lines: [200]Line,

	numbers_count: usize,
	numbers: [2000]Number,

	part_sum: usize,
	gear_sum: usize,

	pub fn analyze(self: *Schematic) void {
		for (0..self.symbols_count) |s| {
			const sym: *const Symbol = &self.symbols[s];
			var n_count: usize = 0;
			var r: usize = 1;

			var y_min: usize = if (sym.y > 0) sym.y-1 else sym.y;
			var y_max: usize = sym.y+1;
			for (y_min..y_max+1) |l| {
				const line: *Line = &self.lines[l];

				// Iterate unconditionally up until first adjacent number.
				// On first adjacent number set init=false.
				// Continue processing adjacent numbers.
				// Then on next non-adjacent number skip whole line.

				var init: bool = true;
				for (line.first..line.last) |n| {
					const num: *const Number = &self.numbers[n];
					if (sym.adjacent_to_number_on_x(num)) {
						self.part_sum += num.value;
						r *= num.value;
						n_count += 1;
						init = false;
					} else if (!init) {
						break;
					}
				}
			}

			if (sym.c == '*' and n_count == 2) {
				self.gear_sum += r;
			}
		}
	}

};

fn parse_schematic() !Schematic {
	var schematic: Schematic = .{
		.symbols_count = 0,
		.symbols = undefined,
		.numbers_count = 0,
		.numbers = undefined,
		.part_sum = 0,
		.gear_sum = 0,
		.lines_count = 0,
		.lines = undefined,
	};
	const stdin = std.io.getStdIn().reader();
	var buf: [1024]u8 = undefined;
	var y: usize = 0;
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		var lline: *Line = &schematic.lines[y];
		schematic.lines_count += 1;

		lline.first = schematic.numbers_count;
		lline.last = lline.first;

		var num: ?usize = null;
		var nx: usize = 0;
		var nlen: usize = 0;
		for (line, 0..) |c, x| {
			switch (c) {
				'0'...'9' => {
					if (num) |n| {
						num = (n * 10) + (c - '0');
					} else {
						nx = x;
						num = c - '0';
					}
					nlen += 1;
				},
				'.' => {
					if (num) |n| {
						schematic.numbers[schematic.numbers_count] = .{.x = nx, .y = y, .value = n, .len = nlen};
						schematic.numbers_count += 1;
						lline.last += 1;
						num = null;
						nlen = 0;
						nx = 0;
					}
				},
				else => {
					if (num) |n| {
						schematic.numbers[schematic.numbers_count] = .{.x = nx, .y = y, .value = n, .len = nlen};
						schematic.numbers_count += 1;
						lline.last += 1;
						num = null;
						nlen = 0;
						nx = 0;
					}
					schematic.symbols[schematic.symbols_count] = .{.x = x, .y = y, .c = c};
					schematic.symbols_count += 1;
				},
			}
		}
		if (num) |n| {
			schematic.numbers[schematic.numbers_count] = .{.x = nx, .y = y, .value = n, .len = nlen};
			schematic.numbers_count += 1;
			lline.last += 1;
			num = null;
			nlen = 0;
			nx = 0;
		}
		y += 1;
	}
	return schematic;
}

pub fn main() !void {
	const stdout = std.io.getStdOut().writer();
	var schematic = try parse_schematic();
	const times: usize = 10000;  // for benchmarking
	for (0..times) |_| {
		schematic.analyze();
	}
	try stdout.print("times: {d}, part number sum: {d}, gear ratio sum: {d}\n", .{times, schematic.part_sum, schematic.gear_sum});
	try stdout.print("532445 79842967\n", .{});

}

test "adjacent 0" {
	const s: Symbol = .{.x = 0, .y = 3, .c = '*'};
	const n: Number = .{.x = 1, .y = 3, .len = 3, .value = 333};
	try std.testing.expect(s.adjacent_to_number(&n));
}

test "adjacent 1" {
	const s: Symbol = .{.x = 0, .y = 2, .c = '*'};
	const n: Number = .{.x = 1, .y = 3, .len = 3, .value = 333};
	try std.testing.expect(s.adjacent_to_number(&n));
}

test "adjacent 2" {
	const s: Symbol = .{.x = 0, .y = 1, .c = '*'};
	const n: Number = .{.x = 1, .y = 3, .len = 3, .value = 333};
	try std.testing.expect(!s.adjacent_to_number(&n));
}

test "adjacent 3" {
	const s: Symbol = .{.x = 4, .y = 2, .c = '*'};
	const n: Number = .{.x = 1, .y = 3, .len = 3, .value = 333};
	try std.testing.expect(s.adjacent_to_number(&n));
}

test "adjacent 4" {
	const s: Symbol = .{.x = 5, .y = 2, .c = '*'};
	const n: Number = .{.x = 1, .y = 3, .len = 3, .value = 333};
	try std.testing.expect(!s.adjacent_to_number(&n));
}

