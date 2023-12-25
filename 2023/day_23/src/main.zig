const std = @import("std");

const Node = struct {
	begin: usize,
	end: usize,
	length: usize,
};

const NeighbourIterator = struct {
	const Self = @This();

	idx: usize,
	i: usize,
	map: *const Map,

	pub fn next(self: *Self) ?usize {
		const neighbours = [4]@Vector(2, i64){
			.{1, 0},
			.{-1, 0},
			.{0, 1},
			.{0, -1},
		};
		const forbidden = [4]u8{
			'<',
			'>',
			'^',
			'v',
		};
		var allowed_count: usize = 0;
		var allowed = [4]usize{0, 1, 2, 3};
		const c = self.map.coords_from_idx(self.idx);
		switch (self.map.grid.items[self.idx]) {
		else => {},
		'.' => {
			allowed_count = 4;
		},
		'>' => {
			allowed_count = 1;
			allowed[0] = 0;
		},
		'<' => {
			allowed_count = 1;
			allowed[0] = 1;
		},
		'v' => {
			allowed_count = 1;
			allowed[0] = 2;
		},
		'^' => {
			allowed_count = 1;
			allowed[0] = 3;
		},
		}

		while (self.i < allowed_count) : (self.i += 1) {
			const a = allowed[self.i];
			const P = c + neighbours[a];
			if (self.map.coords_in_map(P[0], P[1])) {
				const I = self.map.idx_from_coords(P[0], P[1]);
				const g = self.map.grid.items[I];
				if (g != '#' and g != forbidden[a]) {
					self.i += 1;
					return I;
				}
			}
		}
		return null;
	}
};

const Map = struct {
	const Self = @This();

	allocator: std.mem.Allocator,
	w: i64,
	h: i64,
	grid: std.ArrayList(u8),

	pub fn deinit(self: Self) void {
		self.grid.deinit();
	}

	pub fn coords_in_map(self: *const Self, x: i64, y: i64) bool {
		return 0 <= x and x < self.w and 0 <= y and y < self.h;
	}

	pub fn idx_from_coords(self: *const Self, x: i64, y: i64) usize {
		return @intCast(y * self.w + x);
	}

	pub fn coords_from_idx(self: *const Self, idx: usize) @Vector(2, i64) {
		const i: i64 = @intCast(idx);
		return .{@rem(i, self.w), @divTrunc(i, self.w)};
	}

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
		self.w = @intCast(row.len);
		self.h += 1;
	}

	pub fn neighbours_of(self: *Self, idx: usize) NeighbourIterator {
		return .{
			.idx = idx,
			.i = 0,
			.map = self,
		};
	}

	pub fn max_distance2(self: *Self, visited: []bool, nodes: *std.ArrayList(Node), idx: usize, E: usize) ?usize {
		const U = nodes.items[idx];
		if (U.end == E) {
			return U.length;
		}
		visited[idx] = true;
		var max_dist: ?usize = null;
		for (nodes.items, 0..) |V, j| {
		 	if (V.begin == U.end) {
				if (visited[j]) {
					continue;
				}
				const dist = self.max_distance2(visited, nodes, j, E);
				if (dist) |d| {
					const D = U.length + d;
					if (max_dist) |md| {
						if (D > md) {
							max_dist = D;
						}
					} else {
						max_dist = D;
					}
				}
			}
		}
		visited[idx] = false;
		return max_dist;
	}

	pub fn max_distance_part1(self: *Self) !usize {
		var path = try self.allocator.alloc(usize, self.grid.items.len);
		defer self.allocator.free(path);

		@memset(path, 1000);

		var nodes = std.ArrayList(Node).init(self.allocator);
		defer nodes.deinit();

		var pending = std.ArrayList(@Vector(3, usize)).init(self.allocator);
		defer pending.deinit();

		const E: usize = @intCast(self.w*self.h-2);
		for (self.grid.items, 0..) |g, i| {
			if (g == '>' or g == '<' or g == 'v' or g == '^' or i == 1) {
				try pending.append(.{i, i, 0});
			}
		}
		var visited = try self.allocator.alloc(bool, self.grid.items.len);
		defer self.allocator.free(visited);
		@memset(visited, false);

		while (pending.items.len > 0) {
			const O = pending.orderedRemove(0);
			const begin = O[0];
			var U = O[1];
			var length = O[2];

			visited[begin] = true;
			visited[U] = true;

			path[U] = begin;
			if ((E == U) or (begin != U and self.grid.items[U] != '.')) {
				var n: Node = .{.begin = begin, .end = U, .length = length};
				try nodes.append(n);
			} else {
				var neighbours_it = self.neighbours_of(U);
				while (neighbours_it.next()) |V| {
					if (self.grid.items[V] == '.' and visited[V]) {
						continue;
					}
					try pending.append(.{begin, V, length+1});
				}
			}
		}

		var B: usize = 0;
		for (nodes.items, 0..) |n, i| {
			if (n.begin == 1) {
				B = i;
				break;
			}
		}
		@memset(visited, false);
		return self.max_distance2(visited, &nodes, B, E) orelse 0;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();
	defer _ = gpa.deinit();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var map = Map.init(allocator);
	defer map.deinit();
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		try map.append_row(line);
	}
	const part1 = try map.max_distance_part1();
	try stdout.print("{d}\n", .{part1});
}

