#include <array>
#include <iostream>
#include <vector>

struct ivec2 {
	int x, y;
};

void star1() {
	std::vector<ivec2> x_positions;
	std::vector<std::string> board;
	std::string line;
	ivec2 board_size;
	int y = 0;
	while (std::getline(std::cin, line)) {
		board_size.x = line.size();
		board.push_back(line);
		for (size_t x = 0; x < line.size(); x++) {
			if (line[x] == 'X') {
				x_positions.push_back({static_cast<int>(x), y});
			}
		}
		y++;
	}
	board_size.y = board.size();

	std::array<ivec2, 8> directions = {
		ivec2{0, -1},
		ivec2{0, 1},
		ivec2{1, 0},
		ivec2{-1, 0},

		ivec2{1, -1},
		ivec2{1, 1},
		ivec2{-1, 1},
		ivec2{-1, -1}
	};
	int count = 0;
	for (auto p : x_positions) {
		for (const auto d : directions) {
			ivec2 P = p;
			std::string xmas = "";
			xmas += board[P.y][P.x];
			P.x += d.x;
			P.y += d.y;
			for (int i = 0; i < 3; i++) {
				if (P.x >= board_size.x || P.x < 0 || P.y >= board_size.y || P.y < 0) {
					break;
				}
				xmas += board[P.y][P.x];
				P.x += d.x;
				P.y += d.y;
			}
			if (xmas == "XMAS") {
				count++;
			}
		}
	}
	std::cout << count << std::endl;
}

void star2() {
	std::vector<ivec2> a_positions;
	std::vector<std::string> board;
	std::string line;
	ivec2 board_size;
	int y = 0;
	while (std::getline(std::cin, line)) {
		board_size.x = line.size();
		board.push_back(line);
		for (size_t x = 0; x < line.size(); x++) {
			if (line[x] == 'A') {
				a_positions.push_back({static_cast<int>(x), y});
			}
		}
		y++;
	}
	board_size.y = board.size();

	int count = 0;
	// TODO
	std::cout << count << std::endl;
}

int main(int argc, char** argv) {
	std::string s = 1 == argc ? "1" : argv[1];
	if ("1" == s) {
		star1();
	} else if ("2" == s) {
		star2();
	} else {
		std::cerr << "unrecognized star number: " + s << std::endl;
		return 1;
	}
	return 0;
}

