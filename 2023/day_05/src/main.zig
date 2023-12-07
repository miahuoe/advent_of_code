const std = @import("std");

const Range = struct {
	begin: usize,
	count: usize,

	pub fn contains(self: Range, value: usize) bool {
		return self.begin <= value and value < self.begin+self.count;
	}

	pub fn first(self: Range) usize {
		return self.begin;
	}

	pub fn last(self: Range) usize {
		return self.begin+self.count-1;
	}

	pub fn format(self: Range, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
		_ = fmt;
		_ = options;
		try writer.print("{d}:{d}", .{self.first(), self.last()});
	}

	pub fn intersection(self: Range, other: Range) ?Range {
		if (self.count == 0 or other.count == 0) {
			return null;
		}
		if (self.contains(other.first()) or self.contains(other.last()) or other.contains(self.first()) or other.contains(self.last())) {
			const begin = @max(self.begin, other.begin);
			const end = @min(self.begin+self.count, other.begin+other.count);
			if (end > begin) {
				return Range{.begin = begin, .count = end-begin};
			}
		}
		return null;
	}
};

const RangeIn = struct {
	in: usize,
	range: Range,
};

const RangeQueue = std.PriorityQueue(RangeIn, void, compare_range_in_by_in);

const RangeMapEntry = struct {
	const Self = @This();

	src: Range,
	dst: Range,
};

const RangeMap = struct {
	const Self = @This();

	entries: std.ArrayList(RangeMapEntry),

	pub fn init(allocator: std.mem.Allocator) Self {
		return Self{
			.entries = std.ArrayList(RangeMapEntry).init(allocator),
		};
	}

	pub fn deinit(self: Self) void {
		self.entries.deinit();
	}

	pub fn insert(self: *Self, src: usize, dst: usize, count: usize) !void {
		try self.entries.append(RangeMapEntry{
			.dst = Range{.begin = dst, .count = count},
			.src = Range{.begin = src, .count = count}
		});
	}

	fn cmp_by_src(context: void, a: RangeMapEntry, b: RangeMapEntry) bool {
		return std.sort.asc(usize)(context, a.src.begin, b.src.begin);
	}

	pub fn sort(self: *Self) void {
		std.sort.insertion(RangeMapEntry, self.entries.items, {}, cmp_by_src);
	}

	pub fn intersections(self: *Self, with: Range, allocator: std.mem.Allocator) !std.ArrayList(Range) {
		self.sort();
		var result = std.ArrayList(Range).init(allocator);

		var cursor: usize = 0;
		for (self.entries.items) |e| {
			var gr = Range{.begin = cursor, .count = e.src.begin - cursor};
			var gi = gr.intersection(with);
			if (gi) |g| {
				try result.append(g);
			}
			var intersection = e.src.intersection(with);
			if (intersection) |it| {
				const r = Range{
					.begin = (it.begin - e.src.begin) + e.dst.begin,
					.count = it.count,
				};
				try result.append(r);
			}
			cursor = e.src.last()+1;
		}

		if (with.last()+1 > cursor) {
			var gr = Range{.begin = cursor, .count = with.last()+1 - cursor};
			var gi = gr.intersection(with);
			if (gi) |g| {
				try result.append(g);
			}
		}
		return result;
	}

	pub fn lookup(self: *const Self, value: usize) usize {
		for (self.entries.items) |e| {
			if (e.src.contains(value)) {
				return (value - e.src.begin) + e.dst.begin;
			}
		}
		return value;
	}
};

pub fn parse_numbers(line: []u8, seeds: *std.ArrayList(usize)) !void {
	var num: ?usize = null;
	for (line) |c| {
		switch (c) {
			'0'...'9' => {
				if (num) |n| {
					num = (n * 10) + (c - '0');
				} else {
					num = c - '0';
				}
			},
			else => {
				if (num) |n| {
					try seeds.append(n);
					num = null;
				}
			},
		}
	}
	if (num) |n| {
		try seeds.append(n);
	}
}

pub fn part_1() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	var buf: [8192]u8 = undefined;
	var seeds = std.ArrayList(usize).init(allocator);
	defer seeds.deinit();
	var line = try stdin.readUntilDelimiterOrEof(&buf, '\n');
	if (line) |l| {
		try parse_numbers(l, &seeds);
	}
	_ = try stdin.readUntilDelimiterOrEof(&buf, '\n');

	var maps: [7]RangeMap = undefined;
	for (0..7) |i| {
		maps[i] = RangeMap.init(allocator);
		_ = try stdin.readUntilDelimiterOrEof(&buf, '\n');
		while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |lline| {
			if (0 == lline.len) {
				break;
			}
			var numbers = std.ArrayList(usize).init(allocator);
			defer numbers.deinit();
			try parse_numbers(lline, &numbers);
			try maps[i].insert(numbers.items[1], numbers.items[0], numbers.items[2]);
		}
		maps[i].sort();
	}
	var min_location: ?usize = null;
	for (seeds.items) |s| {
		var prev = s;
		for (0..7) |i| {
			const next = maps[i].lookup(prev);
			prev = next;
		}
		if (min_location) |ml| {
			if (prev < ml) {
				min_location = prev;
			}
		} else {
			min_location = prev;
		}
	}
	std.log.debug("answer {?}", .{min_location});

	for (0..7) |i| {
		maps[i].deinit();
	}
}

pub fn compare_range_in_by_in(_: void, a: RangeIn, b: RangeIn) std.math.Order {
	return std.math.order(b.in, a.in);
}

pub fn part_2() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	var buf: [8192]u8 = undefined;
	var seeds = std.ArrayList(usize).init(allocator);
	defer seeds.deinit();
	var line = try stdin.readUntilDelimiterOrEof(&buf, '\n');
	if (line) |l| {
		try parse_numbers(l, &seeds);
	}
	_ = try stdin.readUntilDelimiterOrEof(&buf, '\n');

	var maps: [7]RangeMap = undefined;
	for (0..7) |i| {
		maps[i] = RangeMap.init(allocator);
		_ = try stdin.readUntilDelimiterOrEof(&buf, '\n');
		while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |lline| {
			if (0 == lline.len) {
				break;
			}
			var numbers = std.ArrayList(usize).init(allocator);
			defer numbers.deinit();
			try parse_numbers(lline, &numbers);
			try maps[i].insert(numbers.items[1], numbers.items[0], numbers.items[2]);
		}
		maps[i].sort();
	}
	var ranges = RangeQueue.init(allocator, {});
	defer ranges.deinit();
	for (0..seeds.items.len/2) |si| {
		const begin = seeds.items[si*2+0];
		const count = seeds.items[si*2+1];
		try ranges.add(RangeIn{.in = 0, .range = Range{.begin = begin, .count = count}});
	}
	var min_location: ?usize = null;
	while (ranges.count() > 0) {
		const r = ranges.remove();
		var map = maps[r.in];
		var intersections = try map.intersections(r.range, allocator);
		defer intersections.deinit();
		for (intersections.items) |in| {
			if (r.in < 6) {
				try ranges.add(RangeIn{.in = r.in+1, .range = in});
			} else {
				if (min_location) |ml| {
					if (in.first() < ml) {
						min_location = in.first();
					}
				} else {
					min_location = in.first();
				}
			}
		}
	}
	std.log.debug("{?}", .{min_location});

	for (0..7) |i| {
		maps[i].deinit();
	}
}

pub fn main() !void {
	//try part_1();
	try part_2();
}

test "range" {
	const r = Range{.begin = 0, .count = 10};
	try std.testing.expect(r.contains(0));
	try std.testing.expect(r.contains(1));
	try std.testing.expect(r.contains(9));
	try std.testing.expect(!r.contains(10));
}

test "intersection" {
	const a = Range{.begin = 0, .count = 7};
	const b = Range{.begin = 5, .count = 12};
	const c = a.intersection(b);

	try std.testing.expect(c != null);
	if (c) |C| {
		try std.testing.expectEqual(C.begin, 5);
		try std.testing.expectEqual(C.count, 2);
	}
}

test "intersection null" {
	const a = Range{.begin = 0, .count = 10};
	const b = Range{.begin = 10, .count = 12};
	const c = a.intersection(b);

	try std.testing.expectEqual(c, null);
}

test "intersections map" {
	const allocator = std.testing.allocator;
	var map = RangeMap.init(allocator);
	defer map.deinit();
	try map.insert(0, 10, 2);
	try map.insert(10, 20, 2);
	var r = Range{.begin = 0, .count = 20};
	var intersections = try map.intersections(r, allocator);
	defer intersections.deinit();
	for (intersections.items) |i| {
		std.debug.print("{d}\n", .{i});
	}
}

