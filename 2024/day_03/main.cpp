#include <iostream>
#include <optional>
#include <sstream>
#include <vector>

struct Multiplication {
	long a, b;
};

bool is_valid_number(const std::string& s) {
	for (auto c : s) {
		if (!std::isdigit(c)) {
			return false;
		}
	}
	return true;
}

void try_parse_mul(const std::string& line, size_t& at, std::vector<Multiplication>& muls) {
	at += 4;
	auto comma = line.find(",", at);
	if (!comma) {
		return;
	}
	auto close = line.find(")", comma);
	if (!close) {
		return;
	}
	std::string as = line.substr(at, comma-at);
	std::string bs = line.substr(comma+1, close-(comma+1));
	if (!is_valid_number(as) || !is_valid_number(bs)) {
		return;
	}
	std::stringstream ass(as);
	std::stringstream bss(bs);
	Multiplication m{0, 0};
	if (ass >> m.a && bss >> m.b) {
		muls.push_back(m);
	}
}

std::vector<Multiplication> get_muls(const std::string& line) {
	std::vector<Multiplication> muls{};
	size_t pos = 0;
	for (;;) {
		auto at = line.find("mul(", pos);
		if (at == std::string::npos) {
			break;
		}
		try_parse_mul(line, at, muls);
		pos = at;
	}
	return muls;
}

void star1() {
	std::string line;
	long sum = 0;
	while (std::getline(std::cin, line)) {
		std::vector<Multiplication> muls = get_muls(line);
		for (auto m : muls) {
			sum += m.a * m.b;
		}
	}
	std::cout << sum << std::endl;
}

void star2() {
	throw "not yet implemented";
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

