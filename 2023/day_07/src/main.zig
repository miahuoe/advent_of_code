const std = @import("std");

const HandType = enum(u8) {
	HighCard,
	OnePair,
	TwoPair,
	ThreeOfAKind,
	FullHouse,
	FourOfAKind,
	FiveOfAKind,
};

const Hand = struct {
	cards: [5]u8,
	type: HandType,
	value: usize,
	jokers: u8,

	pub fn card_strength_j(card: u8) ?u8 {
		return switch (card) {
		'A' => 12,
		'K' => 11,
		'Q' => 10,
		'T' => 9,
		'2'...'9' => card-'1',
		'J' => 0,
		else => null,
		};
	}

	pub fn card_strength(card: u8) ?u8 {
		return switch (card) {
		'A' => 12,
		'K' => 11,
		'Q' => 10,
		'J' => 9,
		'T' => 8,
		'2'...'9' => card-'2',
		else => null,
		};
	}

	pub fn format(self: Hand, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
		_ = fmt;
		_ = options;
		try writer.print("Hand(t{d} j{d} [", .{@intFromEnum(self.type), self.jokers});
		for (self.cards) |c| {
			try writer.print(" {d}", .{c});
		}
		try writer.print("])", .{});
	}

	pub fn get_value(self: *const Hand) usize {
		var val: usize = 0;
		val += @intFromEnum(self.type);
		for (self.cards) |c| {
			val *= 13;
			val += c;
		}
		return val;
	}

	pub fn find_type_j(self: *Hand) void {
		var values: [13]u8 = std.mem.zeroes([13]u8);
		for (self.cards) |card| {
			values[card] += 1;
		}
		var j: u8 = values[0];
		values[0] = 0;
		self.jokers = j;
		std.sort.insertion(u8, &values, {}, std.sort.desc(u8));
		if (values[0]+j == 5) {
			self.type = .FiveOfAKind;
			return;
		}
		if (values[0]+j == 4) {
			self.type = .FourOfAKind;
			return;
		}
		if (values[0]+j == 3 and values[1] == 2) {
			self.type = .FullHouse;
			return;
		}
		if (values[0] == 3 and values[1]+j == 2) {
			self.type = .FullHouse;
			return;
		}
		if (values[0]+j == 3) {
			self.type = .ThreeOfAKind;
			return;
		}
		if (values[0] == 3) {
			self.type = .ThreeOfAKind;
			return;
		}
		if (values[0] == 2 and values[1]+j == 2) {
			self.type = .TwoPair;
			return;
		}
		if (values[0]+j == 2) {
			self.type = .OnePair;
			return;
		}
		self.type = .HighCard;
	}

	pub fn find_type(self: *Hand) void {
		var values: [13]u8 = std.mem.zeroes([13]u8);
		for (self.cards) |card| {
			values[card] += 1;
		}
		std.sort.insertion(u8, &values, {}, std.sort.desc(u8));
		if (values[0] == 5) {
			self.type = .FiveOfAKind;
			return;
		}
		if (values[0] == 4) {
			self.type = .FourOfAKind;
			return;
		}
		if (values[0] == 3 and values[1] == 2) {
			self.type = .FullHouse;
			return;
		}
		if (values[0] == 3 and values[1] == 1 and values[2] == 1) {
			self.type = .ThreeOfAKind;
			return;
		}
		if (values[0] == 2 and values[1] == 2) {
			self.type = .TwoPair;
			return;
		}
		if (values[0] == 2 and values[1] == 1 and values[2] == 1 and values[3] == 1) {
			self.type = .OnePair;
			return;
		}
		self.type = .HighCard;
	}
};

const HandBid = struct {
	hand: Hand,
	bid: u32,

	pub fn parse(line: []u8) ?HandBid {
		var i: usize = 0;
		var hb: HandBid = .{.hand = .{.cards = undefined, .type = undefined, .value = 0, .jokers = 0}, .bid = 0};
		while (i < line.len) : (i += 1) {
			const c = line[i];
			if (c == ' ') {
				i += 1;
				break;
			}
			hb.hand.cards[i] = Hand.card_strength(c) orelse return null;
		}
		while (i < line.len) : (i += 1) {
			const c = line[i];
			hb.bid *= 10;
			hb.bid += c - '0';
		}
		hb.hand.find_type();
		hb.hand.value = hb.hand.get_value();
		return hb;
	}

	pub fn parse_j(line: []u8) ?HandBid {
		var i: usize = 0;
		var hb: HandBid = .{.hand = .{.cards = undefined, .type = undefined, .value = 0, .jokers = 0}, .bid = 0};
		while (i < line.len) : (i += 1) {
			const c = line[i];
			if (c == ' ') {
				i += 1;
				break;
			}
			hb.hand.cards[i] = Hand.card_strength_j(c) orelse return null;
		}
		while (i < line.len) : (i += 1) {
			const c = line[i];
			hb.bid *= 10;
			hb.bid += c - '0';
		}
		hb.hand.find_type_j();
		hb.hand.value = hb.hand.get_value();
		return hb;
	}
};

pub fn sort_by_value(context: void, a: HandBid, b: HandBid) bool {
	return std.sort.asc(usize)(context, a.hand.value, b.hand.value);
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	var buf: [8192]u8 = undefined;
	var hands = std.ArrayList(HandBid).init(allocator);
	defer hands.deinit();

	var hands_j = std.ArrayList(HandBid).init(allocator);
	defer hands_j.deinit();

	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		var hb = HandBid.parse(line) orelse break;
		try hands.append(hb);

		var hb_j = HandBid.parse_j(line) orelse break;
		try hands_j.append(hb_j);
	}
	std.sort.insertion(HandBid, hands.items, {}, sort_by_value);
	std.sort.insertion(HandBid, hands_j.items, {}, sort_by_value);
	var sum: usize = 0;
	for (hands.items, 1..) |h, rank| {
		sum += h.bid * rank;
	}
	var sum_j: usize = 0;
	for (hands_j.items, 1..) |h, rank| {
		sum_j += h.bid * rank;
	}
	std.log.debug("answer part 1: {d}", .{sum});
	std.log.debug("answer part 2: {d}", .{sum_j});
}

test "card strength" {
	try std.testing.expectEqual(Hand.card_strength('A'), 12);
	try std.testing.expectEqual(Hand.card_strength('9'), 7);
	try std.testing.expectEqual(Hand.card_strength('2'), 0);
	try std.testing.expectEqual(Hand.card_strength('X'), null);
}

test "hand value" {
	const h1 = Hand{.cards = [5]u8{0, 1, 2, 3, 4}, .type = .FullHouse, .value = 0};
	const h2 = Hand{.cards = [5]u8{0, 1, 2, 3, 4}, .type = .FiveOfAKind, .value = 0};
	try std.testing.expect(h1.get_value() < h2.get_value());
}

