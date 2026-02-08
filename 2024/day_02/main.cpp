#include <iostream>
#include <sstream>
#include <vector>

bool is_safe1(const std::vector<int>& levels, size_t skip_index = 99999999) {
	if (levels.size() <= 1) {
		return false;
	}
	int increasing = 0;
	int decreasing = 0;
	for (size_t i = 0; i < levels.size()-1; i++) {
		size_t ai = i;
		size_t bi = i+1;
		if (ai == skip_index) {
			ai++;
			bi++;
			i++;
		}
		if (bi == skip_index) {
			bi++;
		}
		if (bi == levels.size()) {
			break;
		}

		int d = levels[bi] - levels[ai];
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
	int safe_count = 0;
	std::string line;
	while (std::getline(std::cin, line)) {
		std::stringstream ss(line);
		std::vector<int> levels;
		int level;
		while (ss >> level) {
			levels.push_back(level);
		}
		if (is_safe1(levels)) {
			safe_count++;
		}
	}
	std::cout << safe_count << std::endl;
}

bool is_safe2(std::vector<int>& levels) {
#if 0
	// VERSION 1 copy, erase, check
	if (is_safe1(levels)) {
		return true;
	}
	for (size_t i = 0; i < levels.size(); i++) {
		std::vector levels_a = levels;
		levels_a.erase(levels_a.begin() + i);
		if (is_safe1(levels_a)) {
			return true;
		}
	}
	return false;
#else
	// VERSION 2 don't copy, skip a single index
	if (is_safe1(levels)) {
		return true;
	}
	for (size_t i = 0; i < levels.size(); i++) {
		if (is_safe1(levels, i)) {
			return true;
		}
	}
	return false;
#endif
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
	std::string star = 1 == argc ? "1" : argv[1];
	if ("1" == star) {
		star1();
	} else if ("2" == star) {
		star2();
	} else {
		std::cerr << "unrecognized star number: " + star << std::endl;
		return 1;
	}
	return 0;
}

