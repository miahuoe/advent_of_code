const std = @import("std");

pub fn parse_history_line(comptime T: type, line: []u8, history: *std.ArrayList(T)) !void {
	history.clearRetainingCapacity();
	var sign: T = 1;
	var num: ?T = null;
	for (line) |c| {
		switch (c) {
		'-' => {
			sign = -1;
		},
		'0'...'9' => {
			if (num) |n| {
				num = (n * 10) + (c - '0');
			} else {
				num = c - '0';
			}
		},
		else => {
			if (num) |n| {
				try history.append(sign * n);
				sign = 1;
				num = null;
			}
		},
		}
	}
	if (num) |n| {
		try history.append(sign * n);
	}
}

pub fn extrapolate(comptime T: type, dir: i8, allocator: std.mem.Allocator, H: *std.ArrayList(T)) !T {
	var all_same: bool = true;
	for (1..H.items.len) |i| {
		all_same = all_same and H.items[i-1] == H.items[i];
	}
	if (all_same) {
		return H.items[0];
	}
	var ref: T = undefined;
	if (dir == 1) {
		ref = H.items[H.items.len-1];
	} else {
		ref = H.items[0];
	}

	for (0..H.items.len-1) |i| {
		H.items[i] = H.items[i+1] - H.items[i];
	}
	_ = H.pop();

	const d = try extrapolate(T, dir, allocator, H);
	return ref + dir * d;
}

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

	const input = try allocator.alloc(u8, 1<<20);
	defer allocator.free(input);
	const input_len = try stdin.readAll(input);

	var buffer = std.io.FixedBufferStream([]u8){.buffer = input[0..input_len], .pos = 0};

	var line_buf: []u8 = try allocator.alloc(u8, 1024);
	defer allocator.free(line_buf);

	var history = std.ArrayList(i64).init(allocator);
	defer history.deinit();
	try history.ensureTotalCapacityPrecise(100);

	for (0..iterations) |_| {
		const dirs: [2]i8 = [2]i8{1, -1};
		for (dirs) |dir| {
			buffer.reset();
			var in = buffer.reader();
			var sum: i64 = 0;
			while (try in.readUntilDelimiterOrEof(line_buf, '\n')) |history_str| {
				try parse_history_line(i64, history_str, &history);
				if (0 == history.items.len) {
					break;
				}
				const e = try extrapolate(i64, dir, allocator, &history);
				sum += e;
			}
			try w.print("{d}\n", .{sum});
		}
		try bw.flush();
	}
}

