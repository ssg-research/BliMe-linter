// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
//
// This doesn't currently do much useful things, the idea would be to test how
// explicit return value blinding affects things, but that isn't currently
// implemented.

#define noinline __attribute__((noinline))
#define blinded __attribute__((blinded))

blinded int g_arr[10];
blinded int g_blinded = 0;

int get_blinded_undefined(int i);

// CHECK-LABEL: @get_blinded_defined
// blinded noinline int get_blinded_defined(int i) {
noinline int get_blinded_defined(int i) {
  return g_arr[i] + g_blinded;
}

// CHECK-LABEL: @test_defined
// CHECK: call{{.*}}@_cloned_get_blinded_defined.1
int test_defined(blinded int a) {
  int l_blinded = g_blinded;
  return get_blinded_defined(l_blinded);
}

// CHECK-LABEL: @test_undefined
int test_undefined(blinded int a) {
  int l_blinded = g_blinded;
  return get_blinded_undefined(l_blinded);
}