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

const label_len = 16;

const Instruction = struct {
	label_count: usize,
	label: [label_len]u8,
	box: u8,
	op: u8,
	focal_length: u8,

	pub fn from(s: []const u8) Instruction {
		var ins = Instruction{
			.label_count = 0,
			.label = std.mem.zeroes([label_len]u8),
			.op = undefined,
			.box = undefined,
			.focal_length = 0,
		};
		var i: usize = 0;
		while (i < s.len) : (i += 1) {
			switch (s[i]) {
			else => {},
			'a'...'z' => {
				ins.label[ins.label_count] = s[i];
				ins.label_count += 1;
			},
			'=','-' => {
				ins.op = s[i];
			},
			'0'...'9' => {
				ins.focal_length *= 10;
				ins.focal_length += s[i] - '0';
			},
			}
		}
		ins.box = hash(ins.label[0..ins.label_count]);
		return ins;
	}
};

const Boxes = struct {
	boxes: [256]std.ArrayList(Instruction),

	pub fn deinit(self: Boxes) void {
		for (self.boxes) |b| {
			b.deinit();
		}
	}

	pub fn init(allocator: std.mem.Allocator) !Boxes {
		var self: Boxes = undefined;
		for (0..self.boxes.len) |i| {
			self.boxes[i] = std.ArrayList(Instruction).init(allocator);
		}
		return self;
	}

	pub fn remove(self: *Boxes, ins: Instruction) void {
		var box = &self.boxes[ins.box];
		for (0..box.items.len) |i| {
			if (std.mem.eql(u8, &box.items[i].label, &ins.label)) {
				_ = self.boxes[ins.box].orderedRemove(i);
				break;
			}
		}
	}

	pub fn add(self: *Boxes, ins: Instruction) !void {
		var box = &self.boxes[ins.box];
		for (0..box.items.len) |i| {
			if (std.mem.eql(u8, &box.items[i].label, &ins.label)) {
				box.items[i] = ins;
				return;
			}
		}
		try box.append(ins);
	}
};

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var boxes = try Boxes.init(allocator);
	defer boxes.deinit();

	var buf = try allocator.alloc(u8, 1<<20);
	defer allocator.free(buf);

	while (try stdin.readUntilDelimiterOrEof(buf, '\n')) |line| {
		var it = std.mem.tokenizeAny(u8, line, " ,");
		var part1: usize = 0;
		var part2: usize = 0;
		while (it.next()) |is| {
			part1 += hash(is);
			const ins = Instruction.from(is);
			switch (ins.op) {
			else => {},
			'=' => {
				try boxes.add(ins);
			},
			'-' => {
				boxes.remove(ins);
			},
			}
		}
		for (boxes.boxes, 0..) |b, bi| {
			try stdout.print("Box {d}:", .{bi});
			for (b.items) |i| {
				try stdout.print(" [{s} {d}]", .{i.label[0..i.label_count], i.focal_length});
			}
			try stdout.print("\n", .{});
		}
		for (boxes.boxes, 1..) |b, box| {
			for (b.items, 1..) |i, slot| {
				part2 += box * slot * i.focal_length;
			}
		}
		try stdout.print("{d} {d}\n", .{part1, part2});
	}
}

