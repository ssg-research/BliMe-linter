// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
//
// Make sure having cycles in the call graph doesn't confuse the function
// argument permutation transformations. The function calls in main()
// should trigger multiplication of the other functions, the _no_cylcle
// variants are identical with the exception of the transfrom() function.

// Expect to get new variants for the following functions:
// CHECK-DAG: define dso_local i32 @_cloned_accessArray.{{[a-z0-9]+}}(
// CHECK-DAG: define dso_local i32 @_cloned_accessArray_no_cycle.{{[a-z0-9]+}}(
// CHECK-DAG: define dso_local i32 @_cloned_transform.{{[a-z0-9]+}}(
// CHECK-DAG: define dso_local i32 @_cloned_transform_no_cycle.{{[a-z0-9]+}}(
// CHECK-DAG: define dso_local i32 @_cloned_useKey.{{[a-z0-9]+}}(
// CHECK-DAG: define dso_local i32 @_cloned_useKey_no_cycle.{{[a-z0-9]+}}(

#define noinline __attribute__((noinline))

int useKey(int idx, int idx2, int noTransform);
int useKey_no_cycle(int idx, int idx2, int noTransform);

int arr[100];

noinline
int accessArray(int idx) {
	return arr[idx];
}

noinline
int transform(int idx, int scale, int offset) {
	return scale * useKey(idx, offset, 1); // will cause cycle
}

noinline
int useKey(int idx, int idx2, int noTransform) {
	if (noTransform) return idx + idx2;

	return accessArray(transform(idx + idx2, 2, idx2));
}

noinline
int accessArray_no_cycle(int idx) {
	return arr[idx];
}

noinline
int transform_no_cycle(int idx, int scale, int offset) {
	return scale * (idx + offset); // no cycle
}

noinline
int useKey_no_cycle(int idx, int idx2, int noTransform) {
	if (noTransform) return idx + idx2;

	return accessArray_no_cycle(transform_no_cycle(idx + idx2, 2, idx2));
}

__attribute__((blinded)) int first = 5;
__attribute__((blinded)) int second = 3;

int main() {
  int a = 0;
  int b = 0;
  a = useKey(first, second, 0);
  b = useKey_no_cycle(first, second, 0);
  return a + b;
}
