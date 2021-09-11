// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// XFAIL: *
//
// FIXME: Enable and update once BlindedDataUsage does proper reporting
//
// Make sure we correctly handle cases where a loop is such that it is
// fine on first execution, but will violate the taint-spolicy on
// subsequent iterations.

int arr[100];

int accessArray(int idx) {
	return arr[idx];
}

int transform(int idx, int scale, int offset) {
	return scale * idx + offset;
}

// CHECK: Invalid use of blinded data  as operand of BranchInst
int useKey(__attribute__((blinded)) int idx) {
	int sum = 0;
	int i = 0;
	while (1) {
    // i is non-blinded on first iteration
		sum += accessArray(i);
		if (i != 0) break;

    // But this will taint i for subsequent iterations and
    // cause the previous if statement to violate the policy!
		i = transform(idx, 1, 0);
	}

	return sum;
}

int main() {
	return useKey(5);
}
