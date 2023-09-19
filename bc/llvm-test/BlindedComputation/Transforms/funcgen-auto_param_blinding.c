// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

int arr[100];

// We expect to have 6 new variants of this function!
// CHECK-LABEL: define {{.*}} @_cloned_accessArray{{\.[a-z0-9]+}}(
// CHECK-LABEL: define {{.*}} @_cloned_accessArray{{\.[a-z0-9]+}}(
// CHECK-LABEL: define {{.*}} @_cloned_accessArray{{\.[a-z0-9]+}}(
// CHECK-LABEL: define {{.*}} @_cloned_accessArray{{\.[a-z0-9]+}}(
// CHECK-LABEL: define {{.*}} @_cloned_accessArray{{\.[a-z0-9]+}}(
__attribute__((noinline))
int accessArray(int idx, int idx2, int idx3) {
	return arr[idx] + arr[idx2] + arr[idx3];
}

__attribute__((noinline))
int useKey(__attribute__((blinded)) int idx) {
	return accessArray(idx, 1, 1) + accessArray(1, idx, 1) + accessArray(1, 1, idx) + accessArray(2 * idx, 0, idx + 1) + accessArray(idx, idx, idx)
		+ accessArray(2 * idx, 3 * idx, idx + 5);
}

int main() {
	return useKey(5);
}
