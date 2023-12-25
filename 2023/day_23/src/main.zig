const std = @import("std");

const Node = struct {
	begin: usize,
	end: usize,
	length: usize,

	pub fn sort(self: *Node) void {
		if (self.begin > self.end) {
			const tmp = self.begin;
			self.begin = self.end;
			self.end = tmp;
		}
	}

	pub fn eql(self: Node, other: Node) bool {
		return self.begin == other.begin and self.end == other.end;
	}

	pub fn cmp(_: void, a: Node, b: Node) bool {
		if (a.begin == b.begin) {
			return a.end < b.end;
		}
		return a.begin < b.begin;
	}
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

	pub fn prepare_part2(self: *Self) void {
		for (0..self.grid.items.len) |i| {
			const g = self.grid.items[i];
			if (g == '>' or g == '<' or g == 'v' or g == '^') {
				self.grid.items[i] = '.';
			}
		}
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

	pub fn max_distance_helper(self: *Self, visited: []bool, nodes: *std.ArrayList(Node), idx: usize, E: usize) ?usize {
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
				const dist = self.max_distance_helper(visited, nodes, j, E);
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

	pub fn max_distance_part2_helper(self: *Self, visited: []bool, nodes: *std.ArrayList(Node), idx: usize, junction: usize, end: usize) ?usize {
		const U = nodes.items[idx];
		if (U.end == end or U.begin == end) {
			return U.length;
		}
		visited[junction] = true;
		var max_dist: ?usize = null;
		for (nodes.items, 0..) |V, j| {
			var do = false;
			var new_junction: usize = 0;
			if (V.begin == junction) {
				do = !visited[V.end];
				new_junction = V.end;
			}
			if (V.end == junction) {
				do = !visited[V.begin];
				new_junction = V.begin;
			}
			if (!do) {
				continue;
			}
			const dist = self.max_distance_part2_helper(visited, nodes, j, new_junction, end);
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
		visited[junction] = false;
		return max_dist;
	}

	pub fn max_distance_part1(self: *Self) !usize {
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
		return self.max_distance_helper(visited, &nodes, B, E) orelse 0;
	}

	pub fn max_distance_part2(self: *Self) !usize {
		var nodes = std.ArrayList(Node).init(self.allocator);
		defer nodes.deinit();

		var pending = std.ArrayList(@Vector(4, usize)).init(self.allocator);
		defer pending.deinit();

		const E: usize = @intCast(self.w*self.h-2);

		var visited = try self.allocator.alloc(bool, self.grid.items.len);
		defer self.allocator.free(visited);
		@memset(visited, false);

		try pending.append(.{0, 1, 1, 0});

		while (pending.items.len > 0) {
			const O = pending.orderedRemove(0);
			const prev = O[0];
			const begin = O[1];
			var U = O[2];
			var length = O[3];

			var neighbours = std.ArrayList(usize).init(self.allocator);
			defer neighbours.deinit();
			var neighbours_it = self.neighbours_of(U);
			while (neighbours_it.next()) |V| {
				if (V == prev) {
					continue;
				}
				try neighbours.append(V);
			}
			if (neighbours.items.len == 0) {
				try nodes.append(.{.begin = begin, .end = U, .length = length});
			} else if (neighbours.items.len > 1 or U == E) {
				try nodes.append(.{.begin = begin, .end = U, .length = length});
				if (!visited[U]) {
					for (neighbours.items) |V| {
						try pending.append(.{U, U, V, 1});
					}
					visited[U] = true;
				}
			} else {
				for (neighbours.items) |V| {
					try pending.append(.{U, begin, V, length+1});
				}
			}
		}

		const N = nodes.items.len;
		for (0..N) |i| {
			nodes.items[i].sort();
		}
		std.sort.insertion(Node, nodes.items, {}, Node.cmp);
		var ii: usize = 1;
		while (ii < nodes.items.len) {
			if (nodes.items[ii-1].eql(nodes.items[ii])) {
				_ = nodes.orderedRemove(ii-1);
				continue;
			}
			ii += 1;
		}

		var B: usize = 0;
		for (nodes.items, 0..) |n, i| {
			if (n.begin == 1) {
				B = i;
				break;
			}
		}

		var vis = try self.allocator.alloc(bool, self.grid.items.len);
		defer self.allocator.free(vis);
		@memset(vis, false);

		visited[B] = true;
		return self.max_distance_part2_helper(vis, &nodes, B, nodes.items[B].end, E) orelse 0;
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

	map.prepare_part2();

	const part2 = try map.max_distance_part2();
	try stdout.print("{d}\n", .{part2});
}

