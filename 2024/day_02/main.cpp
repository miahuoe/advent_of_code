#include <iostream>
#include <sstream>
#include <vector>

bool is_safe2(const std::vector<int>& levels) {
	return false; // TODO
}

bool is_safe1(const std::vector<int>& levels) {
	if (levels.size() <= 1) {
		return false;
	}
	int increasing = 0;
	int decreasing = 0;
	for (size_t i = 1; i < levels.size(); i++) {
		int d = levels[i] - levels[i-1];
		if (d < 0) {
			decreasing++;
		} else if (d > 0) {
			increasing++;
		}
		d = std::abs(d);
		if (d < 1 || 3 < d) {
			return false;
		}
		if (increasing > 0 && decreasing > 0) {
			return false;
		}
	}
	return true;
}

void star1() {
	std::string line;
	int safe_count = 0;
	while (std::getline(std::cin, line)) {
		std::stringstream ss(line);
		std::vector<int> levels;
		int num;
		while (ss >> num) {
			levels.push_back(num);
		}
		if (is_safe1(levels)) {
			safe_count++;
		}
	}
	std::cout << safe_count << std::endl;
}

void star2() {
	std::string line;
	int safe_count = 0;
	while (std::getline(std::cin, line)) {
		std::stringstream ss(line);
		std::vector<int> levels;
		int num;
		while (ss >> num) {
			levels.push_back(num);
		}
		if (is_safe2(levels)) {
			safe_count++;
		}
	}
	std::cout << safe_count << std::endl;
}

int main(int argc, char** argv) {
	if (1 == argc) {
		star1();
	} else {
		std::string star(argv[1]);
		if ("1" == star) {
			star1();
		} else if ("2" == star) {
			star2();
		} else {
			std::cerr << "unrecognized star number: " + star << std::endl;
			return 1;
		}
	}
	return 0;
}

