int arr[100];

int accessArray(int idx) {
	return arr[idx];
}

int transform(int idx, int scale, int offset) {
	return scale * useKey(idx, offset, 1); // will cause cycle
	// return scale * (idx + offset); // no cycle
}

int useKey(int idx, int idx2, int noTransform) {
	if (noTransform) return idx + idx2;

	return accessArray(transform(idx + idx2, 2, idx2));
}

__attribute__((blinded)) int first = 5;
__attribute__((blinded)) int second = 3;

int main() {
	return useKey(first, second, 0);
}
