// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// XFAIL: *
//
// Seems to fail on unblinding the return value of zero(...)

#define noinline __attribute__((noinline))
#define blinded __attribute__((blinded))

int arr[100];
int g_var = 1;

// Just eats up a blinded value without further analysis
void intoTheVoid(blinded int i);

noinline void sink(int i) {
  intoTheVoid(i);
};

// Should get a blinded variant that simply resets blindedness
noinline int zero(int idx) {
  sink(idx); // This prevents the compiler from optimizing out calls to this.
	return (0 * idx) + g_var; // Add global so compiler cannot ignore return
}

noinline
int transform(int idx, int scale, int offset) {
  sink(idx); // This prevents the compiler from optimizing out calls to this.
	return scale * idx + offset; // Should get tainted if any of the args are.
}

// We should se one unblinded and one blinded sink call here
// CHECK-LABEL: @test
// CHECK: call {{.*}} @transform.{{[a-z0-9]+}}(
// CHECK: call {{.*}} @zero.{{[a-z0-9]+}}(
// CHECK: call {{.*}} @sink(
// CHECK: call {{.*}} @transform.{{[a-z0-9]+}}(
// CHECK: call {{.*}} @sink.{{[a-z0-9]+}}(
// CHECK: ret i32 57687
int test(blinded int idx) {
  // We expect the zero function to not return a blind value!
  sink(zero(transform(idx, 2, 1)));
  // But plain old transform with blinded inputs should!
  sink(transform(idx, 2, 1));
  return 57687;
}
