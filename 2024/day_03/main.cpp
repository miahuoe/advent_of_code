#include <algorithm>
#include <iostream>
#include <optional>
#include <sstream>
#include <vector>

enum class OperationType {
	Multiplication,
	Do,
	Dont,
};

struct Operation {
	OperationType type;
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

void try_parse_mul(const std::string& line, size_t& at, std::vector<Operation>& ops) {
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
	Operation m{OperationType::Multiplication, 0, 0};
	if (ass >> m.a && bss >> m.b) {
		ops.push_back(m);
	}
}

std::vector<Operation> get_ops(const std::string& line) {
	std::vector<Operation> ops{};
	struct Finding {
		size_t at;
		OperationType type;
	};
	size_t pos = 0;
	for (;;) {
		std::vector<Finding> findings;
		auto at_do = line.find("do()", pos);
		if (std::string::npos != at_do) {
			findings.push_back({at_do, OperationType::Do});
		}
		auto at_dont = line.find("don't()", pos);
		if (std::string::npos != at_dont) {
			findings.push_back({at_dont, OperationType::Dont});
		}
		auto at_mul = line.find("mul(", pos);
		if (std::string::npos != at_mul) {
			findings.push_back({at_mul, OperationType::Multiplication});
		}
		if (findings.empty()) {
			break;
		}
		std::sort(findings.begin(), findings.end(), [](const Finding& a, const Finding& b) -> bool {
			return a.at < b.at;
		});
		auto f = findings[0];
		switch (f.type) {
		case OperationType::Multiplication:
			try_parse_mul(line, f.at, ops);
			pos = f.at;
			break;
		case OperationType::Do:
			ops.push_back({OperationType::Do, 0, 0});
			pos = f.at+4;
			break;
		case OperationType::Dont:
			ops.push_back({OperationType::Dont, 0, 0});
			pos = f.at+7;
			break;
		}
	}
	return ops;
}

void star(bool ignore_switches = true) {
	std::string line;
	long sum = 0;
	long s = 1;
	while (std::getline(std::cin, line)) {
		std::vector<Operation> ops = get_ops(line);
		for (auto m : ops) {
			switch (m.type) {
			case OperationType::Multiplication:
				sum += s * m.a * m.b;
				break;
			case OperationType::Do:
				if (!ignore_switches) {
					s = 1;
				}
				break;
			case OperationType::Dont:
				if (!ignore_switches) {
					s = 0;
				}
				break;
			}
		}
	}
	std::cout << sum << std::endl;
}

int main(int argc, char** argv) {
	std::string s = 1 == argc ? "1" : argv[1];
	if ("1" == s) {
		star();
	} else if ("2" == s) {
		star(false);
	} else {
		std::cerr << "unrecognized star number: " + s << std::endl;
		return 1;
	}
	return 0;
}

