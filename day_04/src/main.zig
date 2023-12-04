const std = @import("std");

fn Card(comptime size: usize) type {
	return struct {
		my: [16]u8,
		winning: [16]u8,
		points: usize,
		num_matching: usize,

		pub fn parse(self: *Card(size), line: []u8) void {
			self.my = std.mem.zeroes([16]u8);
			self.winning = std.mem.zeroes([16]u8);
			self.points = 0;
			self.num_matching = 0;

			var card_id = std.mem.split(u8, line, ":");
			_ = card_id.next() orelse return;
			var cards_section = card_id.next() orelse return;
			var cards_my_winning = std.mem.split(u8, cards_section, "|");
			var cards_my = cards_my_winning.next() orelse return;
			var cards_winning = cards_my_winning.next() orelse return;

			var num: ?usize = null;
			for (cards_my) |c| {
				switch (c) {
				'0' ... '9' => {
					if (num) |n| {
						num = (n * 10) + (c - '0');
					} else {
						num = c - '0';
					}
				},
				else => {
					if (num) |n| {
						self.my[n/8] |= std.math.shl(u8, 1, n % 8);
						num = null;
					}
				},
				}
			}
			if (num) |n| {
				self.my[n/8] |= std.math.shl(u8, 1, n % 8);
				num = null;
			}
			for (cards_winning) |c| {
				switch (c) {
				'0' ... '9' => {
					if (num) |n| {
						num = (n * 10) + (c - '0');
					} else {
						num = c - '0';
					}
				},
				else => {
					if (num) |n| {
						self.winning[n/8] |= std.math.shl(u8, 1, n % 8);
						num = null;
					}
				},
				}
			}
			if (num) |n| {
				self.winning[n/8] |= std.math.shl(u8, 1, n % 8);
				num = null;
			}
			for (0..self.my.len) |i| {
				var points: u8 = self.my[i] & self.winning[i];
				for (0..8) |b| {
					if (0 != (points & std.math.shl(u8, 1, b))) {
						self.num_matching += 1;
					}
				}
			}
			if (self.num_matching > 0) {
				self.points = std.math.pow(usize, 2, self.num_matching-1);
			}
		}
	};
}

fn Lottery(comptime size: usize) type {
	return struct {
		comptime size: usize = size,
		card_count: usize,
		num_matching: [size]usize,
		copies: [size]usize,

		pub fn play(self: *Lottery(size)) usize {
			var copies: usize = 0;
			for (0..self.card_count) |i| {
				const j = self.card_count-1-i;
				const nm = self.num_matching[j];
				self.copies[j] = 1;
				var k: usize = 0;
				while (k < nm and j+1+k < self.card_count) : (k += 1) {
					self.copies[j] += self.copies[j+1+k];
				}
				copies += self.copies[j];
			}
			return copies;
		}
	};
}

pub fn main() !void {
	const stdin = std.io.getStdIn().reader();
	var buf: [1024]u8 = undefined;
	var sum: usize = 0;
	var lottery: Lottery(200) = .{.card_count = 0, .num_matching = undefined, .copies = undefined};
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		var card: Card(16) = undefined;
		card.parse(line);
		sum += card.points;
		lottery.num_matching[lottery.card_count] = card.num_matching;
		lottery.card_count += 1;
	}
	var result = lottery.play();
	std.log.debug("{d} {d}", .{sum, result});
}

test "a" {
	const str = "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53";
	var line: [100]u8 = undefined;
	for (0..str.len) |i| {
		line[i] = str[i];
	}
	var card: Card(16) = undefined;
	card.parse(&line);
	try std.testing.expectEqual(card.points, 8);
	try std.testing.expectEqual(card.num_matching, 4);
}

test "card 6" {
	const str = "Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11";
	var line: [100]u8 = undefined;
	for (0..str.len) |i| {
		line[i] = str[i];
	}
	var card: Card(16) = undefined;
	card.parse(&line);
	try std.testing.expectEqual(card.points, 0);
	try std.testing.expectEqual(card.num_matching, 0);
}

