const std = @import("std");

const Direction = enum {
	const Self = @This();

	Left,
	Right,
	Up,
	Down,
	None,

	pub fn opposite(self: Self, other: Self) bool {
		return switch (self) {
		.Left => other == .Right,
		.Right => other == .Left,
		.Up => other == .Down,
		.Down => other == .Up,
		.None => false,
		};
	}
};

const dx = [4]i64{-1, 1, 0, 0};
const dy = [4]i64{0, 0, -1, 1};

const Step = struct {
	const Self = @This();

	x: i64,
	y: i64,
	heat_loss: usize,
	prev: usize,
	cost: usize,

	direction: Direction,
	steps: usize,

	pub fn cmp(_: void, a: Step, b: Step) std.math.Order {
		return std.math.order(a.heat_loss, b.heat_loss);
	}

	pub fn approach(self: Self) usize {
		return @as(usize, @intFromEnum(self.direction)) * 12 + self.steps;
	}
};

const StepQueue = std.PriorityQueue(Step, void, Step.cmp);

const NeighbourIterator = struct {
	const Self = @This();

	map: *const Map,
	i: usize,
	of: Step,

	pub fn next(self: *Self) ?Step {
		while (self.i < 4) : (self.i += 1) {
			var n = self.of;
			n.x += dx[self.i];
			n.y += dy[self.i];
			n.direction = @enumFromInt(self.i);
			n.steps = 0;
			n.cost = 0;
			if (n.direction.opposite(self.of.direction)) {
				continue;
			}
			if (!self.map.contains(&n)) {
				continue;
			}
			self.i += 1;
			return n;
		}
		return null;
	}
};

const Map = struct {
	const Self = @This();

	allocator: std.mem.Allocator,
	w: i64,
	h: i64,
	cost: std.ArrayList(usize),
	visited: std.ArrayList(bool),

	pub fn deinit(self: *Self) void {
		self.cost.deinit();
	}

	pub fn init(allocator: std.mem.Allocator) Self {
		var s = Self{
			.allocator = allocator,
			.w = 0,
			.h = 0,
			.cost = std.ArrayList(usize).init(allocator),
			.visited = std.ArrayList(bool).init(allocator),
		};
		return s;
	}

	pub fn append_row(self: *Self, row: []u8) !void {
		var r = try self.cost.addManyAsSlice(row.len);
		for (row, 0..) |c, i| {
			r[i] = c - '0';
		}
		self.w = @intCast(row.len);
		self.h += 1;
	}

	pub fn contains(self: *const Self, step: *const Step) bool {
		return 0 <= step.x and step.x < self.w and 0 <= step.y and step.y < self.h;
	}

	pub fn index_of(self: *const Self, step: *const Step) usize {
		return @intCast(step.y * self.w + step.x);
	}

	pub fn neighbours_of(self: *const Self, of: Step) NeighbourIterator {
		return .{.map = self, .i = 0, .of = of};
	}

	pub fn visited_node(self: *Self, n: Step) bool {
		const p = self.index_of(&n);
		const a: usize = n.approach();
		return self.visited.items[a * self.cost.items.len + p];
	}

	pub fn visit_node(self: *Self, n: Step) !void {
		const p = self.index_of(&n);
		const a: usize = n.approach();
		self.visited.items[a * self.cost.items.len + p] = true;
	}

	pub fn find_path(self: *Self, min: usize, max: usize) !usize {
		var V = try self.visited.addManyAsSlice(self.cost.items.len*100);
		@memset(V, false);
		var min_hl: usize = 99999999;

		var q = StepQueue.init(self.allocator, {});
		defer q.deinit();

		try q.add(.{
			.x = 0,
			.y = 0,
			.prev = 0,
			.cost = 0,
			.heat_loss = 0,
			.direction = .None,
			.steps = 0,
		});

		while (q.count() > 0) {
			var Q = q.remove();
			const Qi = self.index_of(&Q);
			if (self.visited_node(Q)) {
				continue;
			}
			try self.visit_node(Q);
			var it = self.neighbours_of(Q);
			while (it.next()) |neighbour| {
				var n = neighbour;
				const ni = self.index_of(&n);
				n.prev = Qi;
				n.cost = self.cost.items[ni];
				n.heat_loss = Q.heat_loss + n.cost;
				n.steps = 1;
				if (n.x == self.w-1 and n.y == self.h-1) {
					min_hl = @min(min_hl, n.heat_loss);
					continue;
				}
				if (Q.direction == .None) {
				} else if (Q.direction == n.direction) {
					n.steps += Q.steps;
					if (n.steps > max) {
						continue;
					}
				} else if (Q.steps < min) {
					continue;
				}
				try q.add(n);
			}
		}
		return min_hl;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var map = Map.init(allocator);
	defer map.deinit();
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		try map.append_row(line);
	}
	@memset(map.visited.items, false);
	const part1 = try map.find_path(0, 3);
	try stdout.print("{d}\n", .{part1});

	@memset(map.visited.items, false);
	const part2 = try map.find_path(4, 10);
	try stdout.print("{d}\n", .{part2});
}

