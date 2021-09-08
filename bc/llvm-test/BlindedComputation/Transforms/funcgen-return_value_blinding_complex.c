// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// XFAIL: *
// FIXME: Add proper checks here and remove XFAIL.

int arr[100];

int accessArray(int idx) {
	return arr[idx];
}

int transform(int idx, int scale, int offset) {
	return scale * idx + offset;
}

int useKey(__attribute__((blinded)) int idx) {
	int sum = 0;
	int i = 0;
	while (1) {
		sum += accessArray(i);

		if (i != 0) break;

		i = transform(idx, 1, 0);
	}

	return sum;
}

int main() {
	return useKey(5);
}
