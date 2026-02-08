#include <algorithm>
#include <cassert>
#include <iostream>
#include <unordered_map>
#include <unordered_set>
#include <vector>

void star1() {
	std::vector<long> left, right;
	long L, R;
	while (std::cin >> L >> R) {
		left.push_back(L);
		right.push_back(R);
	}
	assert(left.size() == right.size());

	std::sort(left.begin(), left.end());
	std::sort(right.begin(), right.end());
	long total_distance = 0;
	for (size_t i = 0; i < left.size(); i++) {
		total_distance += std::abs(left[i]-right[i]);
	}
	std::cout << total_distance << std::endl;
}

void star2() {
	std::unordered_set<long> left;
	std::unordered_map<long, long> right;
	long L, R;
	while (std::cin >> L >> R) {
		left.insert(L);
		auto ri = right.find(R);
		if (ri != right.end()) {
			ri->second++;
		} else {
			right.emplace(R, 1);
		}
	}

	long similarity_score = 0;
	for (auto l : left) {
		auto ri = right.find(l);
		if (ri != right.end()) {
			similarity_score += l * ri->second;
		}
	}
	std::cout << similarity_score << std::endl;
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

