const std = @import("std");

fn find_two_digits(s: []const u8) ?u64 {
	var first: ?u64 = null;
	var last: u64 = 0;
	for (s) |c| {
		if (c < '0' or '9' < c) {
			continue;
		}
		last = c - '0';
		first = first orelse c - '0';
	}
	if (first) |f_val| {
		return f_val * 10 + last;
	}
	return null;
}

const Number = struct {
	name: []const u8,
	value: u64,
};

fn find_two_digits_including_words(s: []const u8) ?u64 {
	const numbers = [_]Number{
		//.{.name="0", .value=0},
		.{.name="1", .value=1},
		.{.name="2", .value=2},
		.{.name="3", .value=3},
		.{.name="4", .value=4},
		.{.name="5", .value=5},
		.{.name="6", .value=6},
		.{.name="7", .value=7},
		.{.name="8", .value=8},
		.{.name="9", .value=9},
		.{.name="one", .value=1},
		.{.name="two", .value=2},
		.{.name="three", .value=3},
		.{.name="four", .value=4},
		.{.name="five", .value=5},
		.{.name="six", .value=6},
		.{.name="seven", .value=7},
		.{.name="eight", .value=8},
		.{.name="nine", .value=9},
	};

	var first: ?u64 = null;
	var last: u64 = 0;
	var i: usize = 0;
	while (i < s.len) : (i += 1) {
		match_number: for (numbers) |e| {
			if (i+e.name.len-1 >= s.len) {
				continue;
			}
			var j: usize = 0;
			while (j < e.name.len and i+j < s.len) : (j += 1) {
				if (e.name[j] != s[i+j]) {
					continue :match_number;
				}
			}
			last = e.value;
			first = first orelse e.value;
		}
	}
	if (first) |f_val| {
		return f_val * 10 + last;
	}
	return null;
}

pub fn main() !void {
	var sum: u64 = 0;
	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();
	var buf: [1024]u8 = undefined;
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		const num = find_two_digits_including_words(line);
		if (num) |n| {
			sum += n;
		}
		try stdout.print("{s} {?}\n", .{line, num});
	}
	try stdout.print("{?}\n", .{sum});
}

test "a4" {
	try std.testing.expectEqual(find_two_digits("a4"), 44);
}

test "a4b4" {
	try std.testing.expectEqual(find_two_digits("a4b3"), 43);
}

test "null" {
	try std.testing.expectEqual(find_two_digits("aa"), null);
}

test "one" {
	try std.testing.expectEqual(find_two_digits_including_words("one"), 11);
}

test "onetwo" {
	try std.testing.expectEqual(find_two_digits_including_words("onetwo"), 12);
}

test "one3" {
	try std.testing.expectEqual(find_two_digits_including_words("one3"), 13);
}
