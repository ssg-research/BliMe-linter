// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// XFAIL: *
// FIXME: Add proper checks here and remove XFAIL.

int arr[100];

int zero(int idx) {
	return 0 * idx;
}

int accessArray(int idx) {
	return arr[idx];
}

int transform(int idx, int scale, int offset) {
	return scale * idx + offset;
}

int useKey2(__attribute__((blinded)) int idx) {
	return zero(accessArray(transform(idx, 2, 1))) + accessArray(transform(0, 0, 0));
}

int main() {
	return useKey2(5);
}
