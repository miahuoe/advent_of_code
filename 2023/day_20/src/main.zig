const std = @import("std");

const ModuleName = struct {
	const Self = @This();

	str: [8]u8,

	pub fn from(line: []const u8) ModuleName {
		var mn: ModuleName = undefined;
		@memset(&mn.str, 0);
		for (line, 0..) |c, i| {
			mn.str[i] = c;
		}
		return mn;
	}

	pub fn eql(self: *const Self, other: Self) bool {
		return std.mem.eql(u8, &self.str, &other.str);
	}
};

const ModuleIdx = usize;

const ModuleNames = struct {
	const Self = @This();

	names: std.ArrayList(ModuleName),

	pub fn init(allocator: std.mem.Allocator) Self {
		return .{
			.names = std.ArrayList(ModuleName).init(allocator),
		};
	}

	pub fn deinit(self: *Self) void {
		self.names.deinit();
	}

	pub fn add_module(self: *Self, name: ModuleName) !ModuleIdx {
		const idx: ModuleIdx = @as(ModuleIdx, @intCast(self.names.items.len));
		try self.names.append(name);
		return idx;
	}

	pub fn get_module(self: *Self, name: ModuleName) ?ModuleIdx {
		for (self.names.items, 0..) |n, i| {
			if (n.eql(name)) {
				return @intCast(i);
			}
		}
		return null;
	}
};

const ModuleType = enum {
	Unknown,
	Broadcaster,

	// H -> [off] = [off]
	// H -> [ on] = [ on]
	// L -> [off] = [ on] + H
	// L -> [ on] = [off] + L
	//
	// H(0) -> [0] = [0]
	// H(0) -> [1] = [1]
	// L(1) -> [0] = [1] + H
	// L(1) -> [1] = [0] + L
	FlipFlop,

	// H/L -> [H/L] for that input
	// if all [H] -> send L
	// if any [L] -> send H
	//
	// if all [0] -> send 1
	// if any [1] -> send 0
	Conjunction,
};

const Module = struct {
	type: ModuleType,
	idx: ModuleIdx,
	state: [16]bool,
	on: bool,
	output: bool,
	inputs_count: usize,
	inputs: [16]ModuleIdx,
	outputs_count: usize,
	outputs: [8]ModuleIdx,
	output_slot: [8]usize,
};

const Pulse = struct {
	src: usize,
	state: bool,
};

pub fn lcm(a: usize, b: usize) usize {
        var A: usize = a;
        var B: usize = b;
        while (A != B) {
                if (A > B) {
                        B += b;
                } else {
                        A += a;
                }
        }
        return A;
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();

	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();

	var buf: [1024]u8 = undefined;

	var module_names = ModuleNames.init(allocator);
	defer module_names.deinit();

	var modules = std.ArrayList(Module).init(allocator);
	defer modules.deinit();

	try modules.append(Module{
		.idx = 0,
		.type = .Broadcaster,
		.state = undefined,
		.on = false,
		.output = true,
		.inputs_count = 0,
		.inputs = undefined,
		.outputs_count = 0,
		.outputs = undefined,
		.output_slot = undefined,
	});
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		var it = std.mem.splitSequence(u8, line, " -> ");
		const src = it.next() orelse continue;
		var idx: ModuleIdx = 0;
		if (!std.mem.eql(u8, src, "broadcaster")) {
			const name = ModuleName.from(src[1..]);
			if (module_names.get_module(name)) |i| {
				idx = 1 + i;
				var module = &modules.items[idx];
				module.idx = idx;
				module.type = switch (src[0]) {
					'%' => .FlipFlop,
					'&' => .Conjunction,
					else => unreachable,
				};
			} else {
				idx = 1 + try module_names.add_module(name);
				const module = Module{
					.idx = idx,
					.type = switch (src[0]) {
						'%' => .FlipFlop,
						'&' => .Conjunction,
						else => unreachable,
					},
					.state = undefined,
					.on = false,
					.output = false,
					.inputs_count = 0,
					.inputs = undefined,
					.outputs_count = 0,
					.outputs = undefined,
					.output_slot = undefined,
				};
				try modules.append(module);
			}
		}

		const dsts = it.next() orelse continue;
		var dst_it = std.mem.splitSequence(u8, dsts, ", ");
		while (dst_it.next()) |dst| {
			const name = ModuleName.from(dst);
			var midx: ModuleIdx = 0;
			if (module_names.get_module(name)) |i| {
				midx = 1 + i;
			} else {
				midx = 1 + try module_names.add_module(name);
				const dst_module = Module{
					.idx = midx,
					.type = .Unknown,
					.state = undefined,
					.on = false,
					.output = false,
					.inputs_count = 0,
					.inputs = undefined,
					.outputs_count = 0,
					.outputs = undefined,
					.output_slot = undefined,
				};
				try modules.append(dst_module);
			}
			var module = &modules.items[idx];
			module.outputs[module.outputs_count] = midx;
			module.outputs_count += 1;
		}
	}
	for (0..modules.items.len) |m| {
		var mod = &modules.items[m];
		switch (mod.type) {
		else => {},
		.Conjunction => {
			@memset(&mod.state, true);
		},
		.FlipFlop => {
			mod.on = false;
		},
		}
		for (0..mod.outputs_count) |o| {
			const out_to_idx = mod.outputs[o];
			var mod_out = &modules.items[out_to_idx];
			mod.output_slot[o] = mod_out.inputs_count;
			mod_out.inputs[mod_out.inputs_count] = m;
			mod_out.inputs_count += 1;
		}
	}
	var q = std.ArrayList(Pulse).init(allocator);
	defer q.deinit();

	const rx_idx = 1 + (module_names.get_module(ModuleName.from(&[2]u8{'r', 'x'})) orelse return);

	var inv_count: usize = 0;
	var inv: [16]usize = undefined;
	var invp: [16]?usize = undefined;
	@memset(&invp, null);
	loop_find_pre_rx: for (0..modules.items.len) |m| {
		var mod = &modules.items[m];
		for (0..mod.outputs_count) |o| {
			var out_idx = mod.outputs[o];
			if (out_idx == rx_idx) {
				inv_count = mod.inputs_count;
				@memcpy(inv[0..inv_count], mod.inputs[0..inv_count]);
				break :loop_find_pre_rx;
			}
		}
	}

	var high_pulses: usize = 0;
	var low_pulses: usize = 0;
	var press_idx: usize = 0;
	var part1: usize = 0;
	while (true) : (press_idx += 1) {
		if (press_idx == 1000) {
			part1 = high_pulses*low_pulses;
		}
		var got_all: bool = true;
		for (0..inv_count) |i| {
			got_all = got_all and invp[i] != null;
		}
		if (got_all and press_idx >= 1000) {
			break;
		}
		try q.append(.{.src = 0, .state = true});
		low_pulses += 1;
		while (q.items.len > 0) {
			const pulse = q.orderedRemove(0);
			const mod_idx = pulse.src;
			const signal = pulse.state;
			var mod = &modules.items[mod_idx];
			for (0..mod.outputs_count) |oi| {
				var oidx = mod.outputs[oi];
				var out = &modules.items[oidx];
				if (signal) {
					low_pulses += 1;
					for (0..inv_count) |i| {
						if (inv[i] == oidx) {
							if (invp[i] == null) {
								invp[i] = press_idx;
							}
						}
					}
				} else {
					high_pulses += 1;
				}

				switch (out.type) {
				else => {},
				.Conjunction => {
					out.state[mod.output_slot[oi]] = signal;
					var ones: usize = 0;
					for (0..out.inputs_count) |i| {
						if (out.state[i]) {
							ones += 1;
						}
					}
					try q.append(.{.src = oidx, .state = (0 == ones)});
				},
				.FlipFlop => {
					if (signal) {
						try q.append(.{.src = oidx, .state = out.on});
						out.on = !out.on;
					}
				},
				}
			}
		}
	}

	try stdout.print("{d}\n", .{part1});
	var invpp: [16]usize = undefined;
	for (0..inv_count) |i| {
		if (invp[i]) |p| {
			invpp[i] = p+1;
		}
	}
	std.debug.assert(inv_count == 4);
	var part2: usize = lcm(lcm(invpp[0], invpp[1]), lcm(invpp[2], invpp[3]));
	try stdout.print("{d}\n", .{part2});
}

