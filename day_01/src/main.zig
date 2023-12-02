const std = @import("std");

const CubeSet = struct {
	r: u64,
	g: u64,
	b: u64,
};

const Game = struct {
	id: usize,
	sets_len: usize,
	sets: [16]CubeSet,
};

const GameParseError = error {
	EmptyInput,
	MissingColon,
	WrongGameIdFormat,
	WrongSetFormat,
	UnknownColor,
};

fn parse_game(line: []const u8) !Game {
	var g: Game = .{.id = 0, .sets_len = 0, .sets = undefined};

      	var it = std.mem.split(u8, line, ":");
      	var game_id = it.next() orelse return error.EmptyInput;

      	var game_id_it = std.mem.split(u8, game_id, " ");
      	_ = game_id_it.next() orelse return error.WrongGameIdFormat;
      	const id = game_id_it.next() orelse return error.WrongGameIdFormat;
	g.id = try std.fmt.parseInt(usize, id, 10);

      	const sets = it.next() orelse return error.MissingColon;
      	var sit = std.mem.split(u8, sets, ";");
	loop_sets: while (sit.next()) |set| {
		var cubes = std.mem.split(u8, set, ",");
		var cs: CubeSet = .{.r = 0, .g = 0, .b = 0};
		while (cubes.next()) |cube| {
			var num_color = std.mem.split(u8, cube, " ");
			_ = num_color.next() orelse continue :loop_sets;
			const num_s = num_color.next() orelse return error.WrongSetFormat;
			const color = num_color.next() orelse return error.WrongSetFormat;
			const num = try std.fmt.parseInt(u64, num_s, 10);
			if (std.mem.eql(u8, color, "red")) {
				cs.r = num;
			} else if (std.mem.eql(u8, color, "green")) {
				cs.g = num;
			} else if (std.mem.eql(u8, color, "blue")) {
				cs.b = num;
			} else {
				return error.UnknownColor;
			}
		}
		g.sets[g.sets_len] = cs;
		g.sets_len += 1;
	}
	return g;
}

pub fn main() !void {
	const stdin = std.io.getStdIn().reader();
	const stdout = std.io.getStdOut().writer();
	var buf: [1024]u8 = undefined;
	var limit: CubeSet = .{.r=12, .g=13, .b=14};
	var id_sum: usize = 0;
	var power_sum: usize = 0;
	while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
		var game = parse_game(line) catch continue;
		//std.log.debug("id={?}", .{game.id});
		var i: usize = 0;
		var r_min: ?u64 = null;
		var g_min: ?u64 = null;
		var b_min: ?u64 = null;
		var possible: bool = true;
		while (i < game.sets_len) : (i += 1) {
			const cs = game.sets[i];
			//std.log.debug("{?}: r{?} g{?} b{?}", .{i, cs.r, cs.g, cs.b});
			if (r_min) |r| {
				r_min = @max(r, cs.r);
			} else {
				r_min = cs.r;
			}
			if (g_min) |g| {
				g_min = @max(g, cs.g);
			} else {
				g_min = cs.g;
			}
			if (b_min) |b| {
				b_min = @max(b, cs.b);
			} else {
				b_min = cs.b;
			}
			if (cs.r > limit.r or cs.g > limit.g or cs.b > limit.b) {
				possible = false;
			}
		}
		var r = r_min orelse 0;
		var g = g_min orelse 0;
		var b = b_min orelse 0;
		var power = r * g * b;
		try stdout.print("id={?}, min: r{?} g{?} b{?}, power={?}\n", .{game.id, r, g, b, power});
		power_sum += power;
		if (possible) {
			id_sum += game.id;
		}
	}
	try stdout.print("{?} {?}\n", .{id_sum, power_sum});
}

test "missing colon" {
	_ = try parse_game("Game ");
}

test "missing sets" {
	_ = try parse_game("Game 10:");
}

