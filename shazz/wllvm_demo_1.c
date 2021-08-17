int isDoublePositive(__attribute__((blinded)) int num) {
	if (add(num, num) > 0) {
		return 1;
	} else {
		return 0;
	}
}

int main() {
	return isDoublePositive(5);
}
