const std = @import("std");

const Node = struct {
	id: usize,
	x: i64,
	y: i64,
	dist: usize
};

fn cmp(_: void, a: Node, b: Node) std.math.Order {
	return std.math.order(a.dist, b.dist);
}

const Map = struct {
	w: i64,
	h: i64,
	sx: i64,
	sy: i64,
	cells_len: usize,
	cells: []u8,
	loop: []bool,

	pub fn idx_of(self: *Map, x: i64, y: i64) ?usize {
		if (x < 0 or self.w <= x or y < 0 or self.h <= y) {
			return null;
		}
		return @as(usize, @intCast(self.w * y + x));
	}

	pub fn pos_of(self: *Map, id: usize) ?[2]i64 {
		if (id >= self.w*self.h) {
			return null;
		}
		var pos = [2]i64{0, 0};
		const i = @as(i64, @intCast(id));
		pos[0] = @mod(i, self.w);
		pos[1] = @divTrunc(i, self.w);
		return pos;
	}

	pub fn neighbours_of(self: *Map, id: usize) [2]?usize {
		var nc: usize = 0;
		var ns = [2]?usize{null, null};
		const pos = self.pos_of(id) orelse return ns;
		const c = self.cells[id];
		var dsc: usize = 0;
		var dxs: [2]i64 = undefined;
		var dys: [2]i64 = undefined;
		switch (c) {
		else => return ns,
		'S' => {
			const l_id = self.idx_of(pos[0]-1, pos[1]+0);
			if (l_id) |l| {
				switch (self.cells[l]) {
				else => {},
				'-','L','F' => {
					dxs[dsc] = -1;
					dys[dsc] = 0;
					dsc += 1;
				},
				}
			}
			const r_id = self.idx_of(pos[0]+1, pos[1]+0);
			if (r_id) |r| {
				switch (self.cells[r]) {
				else => {},
				'-','J','7' => {
					dxs[dsc] = 1;
					dys[dsc] = 0;
					dsc += 1;
				},
				}
			}
			const u_id = self.idx_of(pos[0]+0, pos[1]+1);
			if (u_id) |u| {
				switch (self.cells[u]) {
				else => {},
				'|','7','F' => {
					dxs[dsc] = 0;
					dys[dsc] = 1;
					dsc += 1;
				},
				}
			}
			const d_id = self.idx_of(pos[0]+0, pos[1]-1);
			if (d_id) |d| {
				switch (self.cells[d]) {
				else => {},
				'|','L','J' => {
					dxs[dsc] = 0;
					dys[dsc] = -1;
					dsc += 1;
				},
				}
			}
		},
		'F' => {
			dxs[0] = 0;
			dys[0] = 1;

			dxs[1] = 1;
			dys[1] = 0;
		},
		'7' => {
			dxs[0] = 0;
			dys[0] = 1;

			dxs[1] = -1;
			dys[1] = 0;
		},
		'J' => {
			dxs[0] = 0;
			dys[0] = -1;

			dxs[1] = -1;
			dys[1] = 0;
		},
		'L' => {
			dxs[0] = 0;
			dys[0] = -1;

			dxs[1] = 1;
			dys[1] = 0;
		},
		'|' => {
			dxs[0] = 0;
			dys[0] = -1;

			dxs[1] = 0;
			dys[1] = 1;
		},
		'-' => {
			dxs[0] = 1;
			dys[0] = 0;

			dxs[1] = -1;
			dys[1] = 0;
		},
		}
		for (dxs, dys) |dx, dy| {
			const dir = self.idx_of(pos[0]+dx, pos[1]+dy);
			if (dir) |d| {
				ns[nc] = d;
				nc += 1;
			}
		}
		return ns;
	}

	pub fn analyze(self: *Map) void {
		// calculate width, height
		// find starting position
		// compress by removing \n
		self.w = 0;
		self.h = 0;
		var x: i64 = 0;
		var dst: usize = 0;
		for (0..self.cells_len) |i| {
			const c = self.cells[i];
			if (c == 'S') {
				self.sx = x;
				self.sy = self.h;
			}
			if (c == '\n') {
				x = 0;
				self.h += 1;
			} else {
				self.cells[dst] = c;
				dst += 1;
				if (self.h == 0) {
					self.w += 1;
				} else {
					x += 1;
				}
			}
		}
		if (x > 0) {
			self.h += 1;
		}
	}

	pub fn walk_on_loop(self: *Map, allocator: std.mem.Allocator) !usize {
		_ = allocator;
		var start = self.idx_of(self.sx, self.sy) orelse 0; // TODO
		const start_neighbours = self.neighbours_of(start);
		var prev = start;
		var current = start_neighbours[0] orelse start;
		self.loop[start] = true;
		self.loop[current] = true;

		var steps: usize = 1;
		main: while (true) {
			const neighbours = self.neighbours_of(current);
			for (neighbours) |maybe_n| {
				if (maybe_n) |n| {
					if (n == prev) {
						continue;
					}
					self.loop[n] = true;
					if (n == start) {
						break :main;
					}
					prev = current;
					current = n;
					steps += 1;
					continue :main;
				}
			}
		}
		return steps;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	var args = std.process.args();
	_ = args.skip();

	var iterations: usize = 1;
	if (args.next()) |arg_iter| {
		iterations = try std.fmt.parseInt(usize, arg_iter, 10);
	}

	const stdin = std.io.getStdIn().reader();

	var stdout = std.io.getStdOut();
	var bw = std.io.bufferedWriter(stdout.writer());
	const w = bw.writer();

	var map: Map = undefined;
	map.cells = try allocator.alloc(u8, 1<<20);
	map.loop = try allocator.alloc(bool, 1<<20);

	map.cells_len = try stdin.readAll(map.cells);

	map.analyze();

	for (0..iterations) |_| {
		const steps = try map.walk_on_loop(allocator);
		if (false) {
			var y: i64 = 0;
			while (y < map.h) : (y += 1) {
				var x: i64 = 0;
				while (x < map.w) : (x += 1) {
					const idx = map.idx_of(x, y);
					if (idx) |i| {
						const b: usize = if (map.loop[i]) 1 else 0;
						try w.print("{d}", .{b});
					}
				}
				try w.print("\n", .{});
			}
			try w.print("\n", .{});
		}
		try w.print("part 1: {d}\n", .{steps/2+1});
		try bw.flush();
	}
}

