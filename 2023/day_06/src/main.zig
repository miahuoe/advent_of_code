const std = @import("std");

const Race = struct {
	time: i64,
	record: i64,
};

pub fn parse_number(line: []u8) ?i64 {
	var num: ?i64 = null;
	for (line) |c| {
		switch (c) {
			'0'...'9' => {
				if (num) |n| {
					num = (n * 10) + (c - '0');
				} else {
					num = c - '0';
				}
			},
			else => {},
		}
	}
	return num;
}

pub fn parse_numbers(line: []u8, numbers: *std.ArrayList(i64)) !void {
	var num: ?i64 = null;
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
					try numbers.append(n);
					num = null;
				}
			},
		}
	}
	if (num) |n| {
		try numbers.append(n);
	}
}

const ParseError = error {
	InvalidJoinedNumber
};

pub fn parse_races(races: *std.ArrayList(Race), big_race: *Race) !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	var buf: [8192]u8 = undefined;

	var time = std.ArrayList(i64).init(allocator);
	defer time.deinit();
	var record = std.ArrayList(i64).init(allocator);
	defer record.deinit();

	var line_time = try stdin.readUntilDelimiterOrEof(&buf, '\n');
	if (line_time) |l| {
		try parse_numbers(l, &time);
		big_race.time = parse_number(l) orelse return ParseError.InvalidJoinedNumber;
	}
	var line_record = try stdin.readUntilDelimiterOrEof(&buf, '\n');
	if (line_record) |l| {
		try parse_numbers(l, &record);
		big_race.record = parse_number(l) orelse return ParseError.InvalidJoinedNumber;
	}
	for (time.items, record.items) |t, r| {
		try races.append(Race{.time = t, .record = r});
	}
}

pub fn analyze_race(r: Race) usize {
	var ways_to_beat: usize = 0;
	var t: i64 = 1;
	while (t < r.time) : (t += 1) {
		const score = (r.time - t) * t - r.record;
		if (score > 0) {
			ways_to_beat += 1;
		}
	}
	return ways_to_beat;
}

pub fn analyze_race_fast(r: Race) usize {
	const D: f64 = @floatFromInt(r.time);
	const R: f64 = @floatFromInt(r.record);
	const sq_d = @sqrt(D*D - 4*R);
	return @intFromFloat(sq_d);  // TODO may be inexact
}

pub fn analyze_race_fast2(r: Race) usize {
	const T: f64 = @floatFromInt(r.time);
	const D: f64 = @floatFromInt(r.record);  // TODO +1?
	const sq_d = @sqrt(T*T - 4*D);
	// floor & ceil to get area strictly between; "whole" parts that fit range
	const upper = @floor(0.5*(T + sq_d));
	const lower = @ceil(0.5*(T - sq_d));
	const ans = upper - lower + 1;  // since upper and lower are inclusive, 1 is missing to count all items in range
	return @intFromFloat(ans);  // TODO may be inexact
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();
	var races = std.ArrayList(Race).init(allocator);
	defer races.deinit();
	var big_race: Race = undefined;
	try parse_races(&races, &big_race);
	var prod: usize = 1;
	for (races.items) |r| {
		var w = analyze_race(r);
		std.log.debug("{d} {d} | {d}", .{r.time, r.record, w});
		prod *= w;
	}
	std.log.debug("part 1 answer: {d}", .{prod});
	var bw = analyze_race(big_race);
	var bw_fast = analyze_race_fast(big_race);
	var bw_fast2 = analyze_race_fast2(big_race);
	std.log.debug("{d} {d} | {d}/{d}/{d}", .{big_race.time, big_race.record, bw, bw_fast, bw_fast2});
	std.log.debug("part 2 answer: {d}/{d}/{d}", .{bw, bw_fast, bw_fast2});
}

