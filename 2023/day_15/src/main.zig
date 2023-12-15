const std = @import("std");

pub fn hash(input: []const u8) u8 {
	var s: usize = 0;
	for (input) |c| {
		s += c;
		s *= 17;
		s %= 256;
	}
	return @intCast(s & 0xff);
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf = try allocator.alloc(u8, 1<<20);
	defer allocator.free(buf);
	while (try stdin.readUntilDelimiterOrEof(buf, '\n')) |line| {
		var it = std.mem.tokenizeAny(u8, line, " ,");
		var sum: usize = 0;
		while (it.next()) |is| {
			const h = hash(is);
			sum += h;
		}
		try stdout.print("{d}\n", .{sum});
	}
}

