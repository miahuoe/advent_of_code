const std = @import("std");

pub fn parse_history_line(comptime T: type, allocator: std.mem.Allocator, line: []u8) !std.ArrayList(T) {
	var history = std.ArrayList(T).init(allocator);
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
	return history;
}

pub fn extrapolate(comptime T: type, dir: i8, allocator: std.mem.Allocator, history: *std.ArrayList(T)) !T {
	var all_same: bool = true;
	for (1..history.items.len) |i| {
		all_same = all_same and history.items[i-1] == history.items[i];
	}
	if (all_same) {
		return history.items[0];
	}

	var dhistory = std.ArrayList(T).init(allocator);
	defer dhistory.deinit();
	try dhistory.ensureTotalCapacityPrecise(history.items.len-1);

	for (1..history.items.len) |i| {
		const V0 = history.items[i-1];
		const V1 = history.items[i];
		try dhistory.append(V1-V0);
	}

	const d = try extrapolate(T, dir, allocator, &dhistory);

	if (dir == 1) {
		return history.items[history.items.len-1] + d;
	} else {
		return history.items[0] - d;
	}
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
	const stdout = std.io.getStdOut().writer();

	const input = try allocator.alloc(u8, 1<<20);
	defer allocator.free(input);
	const input_len = try stdin.readAll(input);

	var buffer = std.io.FixedBufferStream([]u8){.buffer = input[0..input_len], .pos = 0};

	var line_buf: []u8 = try allocator.alloc(u8, 1024);
	defer allocator.free(line_buf);
	for (0..iterations) |_| {
		const dirs: [2]i8 = [2]i8{1, -1};
		for (dirs) |dir| {
			buffer.reset();
			var in = buffer.reader();
			var sum: i64 = 0;
			while (try in.readUntilDelimiterOrEofAlloc(allocator, '\n', 1<<20)) |history_str| {
				var history = try parse_history_line(i64, allocator, history_str);
				if (0 == history.items.len) {
					break;
				}
				defer history.deinit();
				allocator.free(history_str);
				const e = try extrapolate(i64, dir, allocator, &history);
				sum += e;
			}
			try stdout.print("{d}\n", .{sum});
		}
	}
}

