const std = @import("std");

const Comparsion = enum {
	Lt,
	Gt,
	Always,
};

const DecisionTag = enum {
	Accept,
	Reject,
	Send,
};

const Decision = union(DecisionTag) {
	const Self = @This();

	Accept: void,
	Reject: void,
	Send: [3]u8,

	pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
		_ = fmt;
		_ = options;
		switch (self) {
		.Accept => {
			try writer.print("Accept", .{});
		},
		.Reject => {
			try writer.print("Reject", .{});
		},
		.Send => |name| {
			try writer.print("Send({s})", .{name});
		},
		}
	}
};

pub fn name_from_str(s: []const u8) [3]u8 {
	var n = std.mem.zeroes([3]u8);
	for (s, 0..) |c, i| {
		n[i] = c;
	}
	return n;
}

const PartRange = struct {
	const Self = @This();

	begin: [4]usize,
	end: [4]usize,

	pub fn combs(self: *const Self) usize {
		var p: usize = 1;
		for (self.begin, self.end) |b, e| {
			p *= e-b+1;
		}
		return p;
	}

	pub fn all() Self {
		return .{.begin = [4]usize{1, 1, 1, 1}, .end = [4]usize{4000, 4000, 4000, 4000}};
	}

	pub fn split_ge(self: Self, idx: usize, at: usize) [2]?PartRange {
		var prs = [2]?PartRange{null, null};
		if (at <= self.begin[idx]) {
			prs[1] = self;
		} else if (self.end[idx] < at) {
			prs[0] = self;
		} else {
			var c1 = self;
			c1.end[idx] = at-1;
			prs[0] = c1;

			var c2 = self;
			c2.begin[idx] = at;
			prs[1] = c2;
		}
		return prs;
	}
};

const PartRatings = struct {
	const Self = @This();

	ratings: [4]usize,

	pub fn from_line(line: []const u8) PartRatings {
		var r: usize = 0;
		var pr = PartRatings{.ratings = [4]usize{0, 0, 0, 0}};
		for (line) |c| {
			switch (c) {
			'0'...'9' => {
				pr.ratings[r] *= 10;
				pr.ratings[r] += c - '0';
			},
			else => {
				if (pr.ratings[r] > 0) {
					r += 1;
				}
			},
			}
		}
		return pr;
	}

	pub fn sum(self: *const Self) usize {
		var s: usize = 0;
		for (self.ratings) |r| {
			s += r;
		}
		return s;
	}
};

const Rule = struct {
	const Self = @This();

	cmp: Comparsion,
	cat_idx: usize,
	value: usize,
	decision: Decision,

	pub fn from(line: []const u8) ?Rule {
		var r: Rule = undefined;
		var idx_colon = std.mem.indexOfScalar(u8, line, @as(u8, ':'));
		if (idx_colon == null) {
			r.cmp = .Always;
			switch (line[0]) {
				'A' => {
					r.decision = .Accept;
					r.cmp = .Always;
					return r;
				},
				'R' => {
					r.decision = .Reject;
					r.cmp = .Always;
					return r;
				},
				else => {
					r.cmp = .Always;
					r.decision = Decision{
						.Send = name_from_str(line[0..@min(3, line.len)])
					};
					return r;
				},
			}
		}
		switch (line[0]) {
			'A' => {
				r.decision = .Accept;
				r.cmp = .Always;
				return r;
			},
			'R' => {
				r.decision = .Reject;
				r.cmp = .Always;
				return r;
			},
			'x' => {
				r.cat_idx = 0;
			},
			'm' => {
				r.cat_idx = 1;
			},
			'a' => {
				r.cat_idx = 2;
			},
			's' => {
				r.cat_idx = 3;
			},
			else => return null,
		}
		r.cmp = switch (line[1]) {
		'>' => .Gt,
		'<' => .Lt,
		else => return null,
		};
		r.value = 0;
		var i: usize = 2;
		while (i < line.len) : (i += 1) {
			switch (line[i]) {
			'0'...'9' => {
				r.value *= 10;
				r.value += line[i] - '0';
			},
			else => break,
			}
		}
		i += 1;
		r.decision = switch (line[i]) {
		'A' => .Accept,
		'R' => .Reject,
		else => Decision{.Send = name_from_str(line[i..@min(i+3, line.len)])},
		};
		return r;
	}

	pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
		_ = fmt;
		_ = options;
		switch (self.cmp) {
		.Always => {
			try writer.print("Rule({})", .{self.decision});
		},
		else => {
			try writer.print("Rule({d} {s} {d} {})", .{self.cat_idx, @tagName(self.cmp), self.value, self.decision});
		},
		}
	}
};

const Workflow = struct {
	const Self = @This();
	const Root = [3]u8{'i', 'n', 0};

	allocator: std.mem.Allocator,
	name: [3]u8,
	rules: std.ArrayList(Rule),

	pub fn from_line(line: []const u8, allocator: std.mem.Allocator) !?Self {
		var rules = std.ArrayList(Rule).init(allocator);
		var it = std.mem.tokenizeAny(u8, line, "{},");
		const name = it.next() orelse return null;
		while (it.next()) |r| {
			const R = Rule.from(r) orelse continue;
			try rules.append(R);
		}
		var w = Self{
			.name = name_from_str(name),
			.allocator = allocator,
			.rules = rules,
		};
		return w;
	}

	pub fn apply(self: *const Self, pr: PartRatings) Decision {
		for (self.rules.items) |r| {
			switch (r.cmp) {
			.Always => return r.decision,
			.Gt => {
				if (pr.ratings[r.cat_idx] > r.value) {
					return r.decision;
				}
			},
			.Lt => {
				if (pr.ratings[r.cat_idx] < r.value) {
					return r.decision;
				}
			},
			}
		}
		unreachable;
	}
};

pub fn find_workflow(workflows: std.ArrayList(Workflow), name: [3]u8) ?*Workflow {
	for (workflows.items, 0..) |w, i| {
		if (std.mem.eql(u8, &w.name, &name)) {
			return &workflows.items[i];
		}
	}
	return null;
}

pub fn _count_combinations(workflows: std.ArrayList(Workflow), wn: [3]u8, ri: usize, pr: PartRange) usize {
	var combs: usize = 0;
	var wf = find_workflow(workflows, wn) orelse unreachable;
	var rule = wf.rules.items[ri];
	switch (rule.cmp) {
	.Always => {
		switch (rule.decision) {
		.Accept => {
			combs += pr.combs();
		},
		.Reject => {},
		.Send => |to| {
			combs += _count_combinations(workflows, to, 0, pr);
		},
		}
	},
	.Gt => {
		var split = pr.split_ge(rule.cat_idx, rule.value+1);
		switch (rule.decision) {
		.Accept => {
			if (split[1]) |s| {
				combs += s.combs();
			}
		},
		.Reject => {},
		.Send => |to| {
			if (split[1]) |s| {
				combs += _count_combinations(workflows, to, 0, s);
			}
		},
		}
		if (split[0]) |s| {
			combs += _count_combinations(workflows, wn, ri+1, s);
		}
	},
	.Lt => {
		var split = pr.split_ge(rule.cat_idx, rule.value);
		switch (rule.decision) {
		.Accept => {
			if (split[0]) |s| {
				combs += s.combs();
			}
		},
		.Reject => {},
		.Send => |to| {
			if (split[0]) |s| {
				combs += _count_combinations(workflows, to, 0, s);
			}
		},
		}
		if (split[1]) |s| {
			combs += _count_combinations(workflows, wn, ri+1, s);
		}
	},
	}
	return combs;
}

pub fn count_combinations(workflows: std.ArrayList(Workflow)) usize {
	return _count_combinations(workflows, Workflow.Root, 0, PartRange.all());
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var workflows = std.ArrayList(Workflow).init(allocator);
	defer workflows.deinit();

	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		if (line.len == 0) {
			break;
		}
		const W = try Workflow.from_line(line, allocator) orelse continue;
		try workflows.append(W);
	}

	var parts = std.ArrayList(PartRatings).init(allocator);
	defer parts.deinit();

	var part1: usize = 0;
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		const P = PartRatings.from_line(line);
		try parts.append(P);
		var d = Decision{.Send = Workflow.Root};
		while (true) {
			switch (d) {
			.Accept => {
				part1 += P.sum();
				break;
			},
			.Reject => {
				break;
			},
			.Send => |wn| {
				const W = find_workflow(workflows, wn);
				if (W) |w| {
					d = w.apply(P);
				} else {
					unreachable;
				}
			},
			}
		}
	}
	try stdout.print("{d}\n", .{part1});

	const part2 = count_combinations(workflows);
	try stdout.print("{d}\n", .{part2});
}

test "split range" {
	var pr = PartRange{.begin = [4]usize{1, 1, 1, 1}, .end = [4]usize{4000, 4000, 4000, 400}};
	var prs = pr.split_ge(0, 2000);
	try std.testing.expect(prs[0] != null);
	try std.testing.expect(prs[1] != null);
	if (prs[0]) |p| {
		try std.testing.expectEqual(p.begin[0], 1);
		try std.testing.expectEqual(p.end[0], 1999);
	}
	if (prs[1]) |p| {
		try std.testing.expectEqual(p.begin[0], 2000);
		try std.testing.expectEqual(p.end[0], 4000);
	}
}

test "split range all gt" {
	var pr = PartRange{.begin = [4]usize{2000, 1, 1, 1}, .end = [4]usize{4000, 4000, 4000, 400}};
	var prs = pr.split_ge(0, 1);
	try std.testing.expect(prs[0] == null);
	try std.testing.expect(prs[1] != null);
	if (prs[1]) |p| {
		try std.testing.expectEqual(p.begin[0], 2000);
		try std.testing.expectEqual(p.end[0], 4000);
	}
}

test "combs 2" {
	var pr = PartRange{.begin = [4]usize{1, 1, 1, 1}, .end = [4]usize{2, 1, 1, 1}};
	try std.testing.expectEqual(pr.combs(), 2);
}

test "combs 16" {
	var pr = PartRange{.begin = [4]usize{1, 1, 1, 1}, .end = [4]usize{2, 2, 2, 2}};
	try std.testing.expectEqual(pr.combs(), 16);
}

