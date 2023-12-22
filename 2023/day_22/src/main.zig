const std = @import("std");

const Brick = struct {
	const Self = @This();

	begin: @Vector(3, usize),
	end: @Vector(3, usize),

	supports_count: usize,
	supports: [8]usize,
	supported_count: usize,
	supported: [8]usize,

	pub fn add_supported_by(self: *Self, bidx: usize) void {
		for (0..self.supported_count) |i| {
			if (self.supported[i] == bidx) {
				return;
			}
		}
		self.supported[self.supported_count] = bidx;
		self.supported_count += 1;
	}

	pub fn add_supports(self: *Self, bidx: usize) void {
		for (0..self.supports_count) |i| {
			if (self.supports[i] == bidx) {
				return;
			}
		}
		self.supports[self.supports_count] = bidx;
		self.supports_count += 1;
	}

	pub fn from_line(line: []u8) !?Self {
		var b: Self = undefined;
		b.supports_count = 0;
		b.supported_count = 0;

		var ends_it = std.mem.tokenizeAny(u8, line, "~");
		const begin = ends_it.next() orelse return null;
		const end = ends_it.next() orelse return null;

		var begin_xyz = std.mem.tokenizeAny(u8, begin, ",");

		const begin_x = begin_xyz.next() orelse return null;
		b.begin[0] = try std.fmt.parseInt(usize, begin_x, 10);

		const begin_y = begin_xyz.next() orelse return null;
		b.begin[1] = try std.fmt.parseInt(usize, begin_y, 10);

		const begin_z = begin_xyz.next() orelse return null;
		b.begin[2] = try std.fmt.parseInt(usize, begin_z, 10);

		var end_xyz = std.mem.tokenizeAny(u8, end, ",");

		const end_x = end_xyz.next() orelse return null;
		b.end[0] = try std.fmt.parseInt(usize, end_x, 10);

		const end_y = end_xyz.next() orelse return null;
		b.end[1] = try std.fmt.parseInt(usize, end_y, 10);

		const end_z = end_xyz.next() orelse return null;
		b.end[2] = try std.fmt.parseInt(usize, end_z, 10);

		return b;
	}

	pub fn length(self: *const Self) usize {
		const d = self.direction();
		return (self.end[d] - self.begin[d])+1;
	}

	pub fn direction(self: *const Self) usize {
		for (0..3) |i| {
			if (self.begin[i] != self.end[i]) {
				return i;
			}
		}
		return 2;
	}

	pub fn cmp(context: void, a: Brick, b: Brick) bool {
		return std.sort.asc(usize)(context, a.begin[2], b.begin[2]);
	}
};

const Extents = struct {
	min: @Vector(3, usize),
	max: @Vector(3, usize),
};

pub fn bricks_grid_size(bricks: *std.ArrayList(Brick)) Extents {
	var bounds = Extents{
		.min = @Vector(3, usize){10000, 10000, 10000},
		.max = @Vector(3, usize){0, 0, 0},
	};
	for (bricks.items) |b| {
		for (0..3) |i| {
			bounds.min[i] = @min(bounds.min[i], b.begin[i]);
			bounds.min[i] = @min(bounds.min[i], b.end[i]);
			bounds.max[i] = @max(bounds.max[i], b.begin[i]);
			bounds.max[i] = @max(bounds.max[i], b.end[i]);
		}
	}
	for (0..3) |i| {
		bounds.max[i] += 1;
	}
	return bounds;
}

const Height = struct {
	z: usize,
	bidx: ?usize,
};

pub fn can_be_removed(bricks: *std.ArrayList(Brick), bidx: usize) bool {
	var b = &bricks.items[bidx];
	for (0..b.supports_count) |i| {
		var s = bricks.items[b.supports[i]];
		if (s.supported_count < 2) {
			return false;
		}
	}
	return true;
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();
	defer _ = gpa.deinit();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var bricks = std.ArrayList(Brick).init(allocator);
	defer bricks.deinit();

	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		if (try Brick.from_line(line)) |brick| {
			try bricks.append(brick);
		}
	}
	std.sort.insertion(Brick, bricks.items, {}, Brick.cmp);

	const ex = bricks_grid_size(&bricks);

	var height_map = std.ArrayList(Height).init(allocator);
	defer height_map.deinit();

	var hm = try height_map.addManyAsSlice(ex.max[0]*ex.max[1]);
	@memset(hm, .{.z = 0, .bidx = null});

	for (0..bricks.items.len) |bidx| {
		var b: *Brick = &bricks.items[bidx];
		switch (b.direction()) {
		0 => {
			var max_z: usize = 0;
			for (b.begin[0]..b.end[0]+1) |x| {
				const h = &height_map.items[b.begin[1] * ex.max[0] + x];
				max_z = @max(max_z, h.z);
			}
			for (b.begin[0]..b.end[0]+1) |x| {
				const h = &height_map.items[b.begin[1] * ex.max[0] + x];
				if (h.bidx) |i| {
					if (h.z == max_z) {
						bricks.items[i].add_supports(bidx);
						b.add_supported_by(i);
					}
				}
				h.z = max_z+1;
				h.bidx = bidx;
			}
		},
		1 => {
			var max_z: usize = 0;
			for (b.begin[1]..b.end[1]+1) |y| {
				const h = &height_map.items[y * ex.max[0] + b.begin[0]];
				max_z = @max(max_z, h.z);
			}
			for (b.begin[1]..b.end[1]+1) |y| {
				const h = &height_map.items[y * ex.max[0] + b.begin[0]];
				if (h.bidx) |i| {
					if (h.z == max_z) {
						bricks.items[i].add_supports(bidx);
						b.add_supported_by(i);
					}
				}
				h.z = max_z+1;
				h.bidx = bidx;
			}
		},
		2 => {
			const h = &height_map.items[b.begin[1] * ex.max[0] + b.begin[0]];
			if (h.bidx) |i| {
				b.add_supported_by(i);
				bricks.items[i].add_supports(bidx);
			}
			h.z += b.length();
			h.bidx = bidx;
		},
		else => unreachable,
		}
	}
	var part1: usize = 0;
	for (0..bricks.items.len) |bidx| {
		if (can_be_removed(&bricks, bidx)) {
			part1 += 1;
		}
	}
	try stdout.print("{d}\n", .{part1});
}

