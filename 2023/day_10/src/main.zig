const std = @import("std");

const Node = struct {
	id: usize,
	x: i64,
	y: i64,
	dist: usize
};

const PipeScanState = enum {
	Outside,
	Inside,
	FromInsideAtPipeFromUp,
	FromInsideAtPipeFromDown,
	FromOutsideAtPipeFromUp,
	FromOutsideAtPipeFromDown,
};

const Map = struct {
	w: i64,
	h: i64,
	sx: i64,
	sy: i64,
	cells_len: usize,
	cells: []u8,
	loop: []bool,
	cat: []u8,

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

	pub fn neighbours_of(self: *Map, id: usize) [2]usize {
		var nc: usize = 0;
		var ns = [2]usize{0, 0};
		const pos = self.pos_of(id) orelse return ns;
		const c = self.cells[id];
		var dxs: [2]i64 = undefined;
		var dys: [2]i64 = undefined;
		switch (c) {
		else => unreachable,
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
		std.debug.assert(nc == 2);
		return ns;
	}

	pub fn prepare(self: *Map) void {
		// calculate width, height
		// find starting position
		// compress by removing \n
		// replace S with pipe

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

		const id = self.idx_of(self.sx, self.sy) orelse unreachable;
		var L = false;
		var R = false;
		var U = false;
		var D = false;
		const l_id = self.idx_of(self.sx-1, self.sy+0);
		if (l_id) |l| {
			switch (self.cells[l]) {
			else => {},
			'-','L','F' => {
				L = true;
			},
			}
		}
		const r_id = self.idx_of(self.sx+1, self.sy+0);
		if (r_id) |r| {
			switch (self.cells[r]) {
			else => {},
			'-','J','7' => {
				R = true;
			},
			}
		}
		const d_id = self.idx_of(self.sx+0, self.sy+1);
		if (d_id) |d| {
			switch (self.cells[d]) {
			else => {},
			'|','L','J' => {
				D = true;
			},
			}
		}
		const u_id = self.idx_of(self.sx+0, self.sy-1);
		if (u_id) |u| {
			switch (self.cells[u]) {
			else => {},
			'|','F','7' => {
				U = true;
			},
			}
		}

		if (L and U) {
			self.cells[id] = 'J';
		} else if (L and R) {
			self.cells[id] = '-';
		} else if (L and D) {
			self.cells[id] = '7';
		} else if (R and U) {
			self.cells[id] = 'L';
		} else if (R and D) {
			self.cells[id] = 'F';
		} else if (U and D) {
			self.cells[id] = '|';
		} else {
			unreachable;
		}
	}

	pub fn count_inside(self: *Map) usize {
		@memset(self.cat, '?');
		for (0..@intCast(self.h)) |y| {
			var st: PipeScanState = .Outside;
			for (0..@intCast(self.w)) |x| {
				const I = self.idx_of(@intCast(x), @intCast(y)) orelse continue;
				const C = self.cells[I];
				const L = self.loop[I];
				var in: bool = false;
				switch (st) {
					.Outside => {
						if (L) {
							switch (C) {
								else => unreachable,
								'|' => {
									st = .Inside;
								},
								'F' => {
									st = .FromOutsideAtPipeFromDown;
								},
								'L' => {
									st = .FromOutsideAtPipeFromUp;
								},
							}
						}
					},
					.Inside => {
						if (L) {
							switch (C) {
								else => unreachable,
								'|' => {
									st = .Outside;
								},
								'F' => {
									st = .FromInsideAtPipeFromDown;
								},
								'L' => {
									st = .FromInsideAtPipeFromUp;
								},
							}
						} else {
							in = true;
						}
					},
					.FromInsideAtPipeFromUp => {
						switch (C) {
							else => unreachable,
							'-' => {},
							'J' => {
								if (L) {
									st = .Inside;
								} else {
									unreachable;
								}
							},
							'7' => {
								if (L) {
									st = .Outside;
								} else {
									unreachable;
								}
							},
						}
					},
					.FromInsideAtPipeFromDown => {
						switch (C) {
							else => unreachable,
							'-' => {},
							'J' => {
								if (L) {
									st = .Outside;
								} else {
									unreachable;
								}
							},
							'7' => {
								if (L) {
									st = .Inside;
								} else {
									unreachable;
								}
							},
						}
					},
					.FromOutsideAtPipeFromUp => {
						switch (C) {
							else => unreachable,
							'-' => {},
							'J' => {
								if (L) {
									st = .Outside;
								} else {
									unreachable;
								}
							},
							'7' => {
								if (L) {
									st = .Inside;
								} else {
									unreachable;
								}
							},
						}
					},
					.FromOutsideAtPipeFromDown => {
						switch (C) {
							else => unreachable,
							'-' => {},
							'J' => {
								if (L) {
									st = .Inside;
								} else {
									unreachable;
								}
							},
							'7' => {
								if (L) {
									st = .Outside;
								} else {
									unreachable;
								}
							},
						}
					},
				}
				if (in) {
					self.cat[I] = 'I';
				} else if (L) {
					self.cat[I] = C;
				} else {
					self.cat[I] = 'O';
				}
			}
		}
		var inside: usize = 0;
		for (0..@intCast(self.w*self.h)) |i| {
			if (self.cat[i] == 'I') {
				inside += 1;
			}
		}
		return inside;
	}

	pub fn walk_on_loop(self: *Map) usize {
		var start = self.idx_of(self.sx, self.sy) orelse unreachable;
		const start_neighbours = self.neighbours_of(start);
		var prev = start;
		var current = start_neighbours[0];
		@memset(self.loop, false);
		self.loop[start] = true;
		self.loop[current] = true;

		var steps: usize = 1;
		main: while (true) {
			const neighbours = self.neighbours_of(current);
			for (neighbours) |n| {
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
		return steps;
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var map: Map = undefined;

	map.cells = try allocator.alloc(u8, 1<<20);
	defer allocator.free(map.cells);

	map.loop = try allocator.alloc(bool, 1<<20);
	defer allocator.free(map.loop);

	map.cat = try allocator.alloc(u8, 1<<20);
	defer allocator.free(map.cat);

	map.cells_len = try stdin.readAll(map.cells);
	map.prepare();

	const steps = map.walk_on_loop();
	const inside = map.count_inside();
	try stdout.print("part 1: {d}\n", .{steps/2+1});
	try stdout.print("part 2: {d}\n", .{inside});
}

