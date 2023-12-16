const std = @import("std");

const Direction = enum {
	Right,
	Left,
	Up,
	Down,

	pub fn as_vec(self: Direction) Vec {
		return switch (self) {
		.Right => Vec{.x = 1, .y = 0},
		.Left => Vec{.x = -1, .y = 0},
		.Up => Vec{.x = 0, .y = -1},
		.Down => Vec{.x = 0, .y = 1},
		};
	}

	pub fn as_bit(self: Direction) u8 {
		return switch (self) {
		.Right => 1<<0,
		.Left => 1<<1,
		.Up => 1<<2,
		.Down => 1<<3,
		};
	}
};

const Vec = struct {
	const Self = @This();

	x: i64,
	y: i64,

	pub fn add(self: Self, other: Self) Self {
		return Self{.x = self.x + other.x, .y = self.y + other.y};
	}
};

const Beam = struct {
	position: Vec,
	direction: Direction,
};

const Layout = struct {
	const Self = @This();

	allocator: std.mem.Allocator,
	w: i64,
	h: i64,
	grid: std.ArrayList(u8),
	energy: std.ArrayList(usize),
	beams: std.ArrayList(Beam),

	pub fn reset(self: *Self) void {
		@memset(self.energy.items, 0);
		self.beams.clearRetainingCapacity();
	}

	pub fn deinit(self: *Self) void {
		self.grid.deinit();
		self.energy.deinit();
		self.beams.deinit();
	}

	pub fn init(allocator: std.mem.Allocator) Self {
		return Self{
			.allocator = allocator,
			.w = 0,
			.h = 0,
			.grid = std.ArrayList(u8).init(allocator),
			.energy = std.ArrayList(usize).init(allocator),
			.beams = std.ArrayList(Beam).init(allocator),
		};
	}

	pub fn prepare(self: *Self) !void {
		var e = try self.energy.addManyAsSlice(@intCast(self.w*self.h));
		@memset(e, 0);
	}

	pub fn count_energized_tiles(self: *const Self) usize {
		var c: usize = 0;
		for (self.energy.items) |e| {
			if (e != 0) {
				c += 1;
			}
		}
		return c;
	}

	pub fn append_row(self: *Self, row: []u8) !void {
		var r = try self.grid.addManyAsSlice(row.len);
		@memcpy(r, row);
		self.w = @intCast(row.len);
		self.h += 1;
	}

	pub fn contains(self: *const Self, beam: *const Beam) bool {
		return 0 <= beam.position.x and beam.position.x < self.w and 0 <= beam.position.y and beam.position.y < self.h;
	}

	pub fn run_beams(self: *Self) !void {
		var visited = std.ArrayList(u8).init(self.allocator);
		defer visited.deinit();
		var vs = try visited.addManyAsSlice(@intCast(self.w*self.h));
		@memset(vs, 0);

		while (self.beams.items.len > 0) {
			var beam = self.beams.pop();
			if (!self.contains(&beam)) {
				continue;
			}
			while (true) {
				if (!self.contains(&beam)) {
					break;
				}
				const i: usize = @intCast(beam.position.y * self.w + beam.position.x);
				if (0 != (visited.items[i] & beam.direction.as_bit())) {
					break;
				}
				visited.items[i] |= beam.direction.as_bit();
				const t = self.grid.items[i];
				switch (t) {
				else => {},
				'.' => {
					self.energy.items[i] += 1;
					beam.position = beam.position.add(beam.direction.as_vec());
				},
				'\\' => {
					self.energy.items[i] += 1;
					beam.direction = switch (beam.direction) {
					.Right => .Down,
					.Left => .Up,
					.Up => .Left,
					.Down => .Right,
					};
					beam.position = beam.position.add(beam.direction.as_vec());
				},
				'/' => {
					self.energy.items[i] += 1;
					beam.direction = switch (beam.direction) {
					.Right => .Up,
					.Left => .Down,
					.Up => .Right,
					.Down => .Left,
					};
					beam.position = beam.position.add(beam.direction.as_vec());
				},
				'|' => {
					self.energy.items[i] += 1;
					switch (beam.direction) {
					.Right, .Left => {
						try self.beams.append(.{
							.position = beam.position.add(Direction.Down.as_vec()),
							.direction = .Down,
						});
						beam.direction = .Up;
						beam.position = beam.position.add(Direction.Up.as_vec());
					},
					.Up, .Down => {
						beam.position = beam.position.add(beam.direction.as_vec());
					},
					}
				},
				'-' => {
					self.energy.items[i] += 1;
					switch (beam.direction) {
					.Up, .Down => {
						try self.beams.append(.{
							.position = beam.position.add(Direction.Left.as_vec()),
							.direction = .Left,
						});
						beam.direction = .Right;
						beam.position = beam.position.add(Direction.Right.as_vec());
					},
					.Right, .Left => {
						beam.position = beam.position.add(beam.direction.as_vec());
					},
					}
				},
				}
			}
		}
	}
};

pub fn energy_for_starting_beam(layout: *Layout, beam: Beam) !usize {
	layout.reset();
	try layout.beams.append(beam);
	try layout.run_beams();
	return layout.count_energized_tiles();
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var layout = Layout.init(allocator);
	defer layout.deinit();
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		try layout.append_row(line);
	}
	try layout.prepare();

	const part1 = try energy_for_starting_beam(&layout, .{
		.position = .{.x = 0, .y = 0},
		.direction = .Right
	});
	try stdout.print("{d}\n", .{part1});

	var part2: usize = 0;
	for (0..@intCast(layout.w)) |x| {
		const e1 = try energy_for_starting_beam(&layout, .{
			.position = .{.x = @intCast(x), .y = 0},
			.direction = .Down,
		});
		part2 = @max(part2, e1);
		const e2 = try energy_for_starting_beam(&layout, .{
			.position = .{.x = @intCast(x), .y = layout.h-1},
			.direction = .Up,
		});
		part2 = @max(part2, e2);
	}
	for (0..@intCast(layout.h)) |y| {
		const e1 = try energy_for_starting_beam(&layout, .{
			.position = .{.x = 0, .y = @intCast(y)},
			.direction = .Right,
		});
		part2 = @max(part2, e1);
		const e2 = try energy_for_starting_beam(&layout, .{
			.position = .{.x = layout.w-1, .y = @intCast(y)},
			.direction = .Left,
		});
		part2 = @max(part2, e2);
	}

	try stdout.print("{d}\n", .{part2});
	layout.reset();
}

