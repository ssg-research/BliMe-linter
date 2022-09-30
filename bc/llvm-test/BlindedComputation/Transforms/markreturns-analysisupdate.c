// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
//
// Test whether we are dependent on tranformation order. Specifically, the 
// gimme_blind_* function here are used in simpleTest but are partially
// define both before or after the definition of simpleTest.
// 
// We would expect that both calls to need_blind_var are converted to the
// blinded variant (which does get properly created due to the sanityCheck).
// However, because the calls are nested, the blindedness must propagate
// through the function calls in the gimme_blind chain, which in turn causes
// an error if the transfromation are order dependent and do not properly
// invalidate prior resutls or reprocess functions.
#define noinline __attribute__((noinline))
#define blinded __attribute__((blinded))

blinded int g_arr[10];
blinded int g_blinded = 0;

noinline int gimme_blind_a1(int i);
noinline int gimme_blind_a2(int i);
noinline int gimme_blind_a3(int i);
noinline int gimme_blind_a4(int i);
noinline int gimme_blind_b1(int i);
noinline int gimme_blind_b2(int i);
noinline int gimme_blind_b3(int i);
noinline int gimme_blind_b4(int i);

int gimme_blind_a1(int i) { return gimme_blind_a2(i); }
int gimme_blind_a2(int i) { return gimme_blind_a3(i); }
int gimme_blind_a3(int i) { return gimme_blind_a4(i); }
int gimme_blind_a4(int i) { return g_blinded + i; }

// CHECK-LABEL: @need_blind_var
noinline int need_blind_var(int i) {
  return g_arr[i];
}

// Expect both calls to need_blind_var to have been converted!
//
// CHECK-LABEL: @simpleTest
// CHECK-DAG: call i32 @need_blind_var.1
// CHECK-DAG: call i32 @need_blind_var.1
// CHECK-DAG: call i32 @gimme_blind_a1
// CHECK-DAG: call i32 @gimme_blind_b1
// CHECK: ret i32
int simpleTest(blinded int a) {
  return need_blind_var(gimme_blind_a1(1)) + need_blind_var(gimme_blind_b1(2));
}

int gimme_blind_b1(int i) { return gimme_blind_b2(i); }
int gimme_blind_b2(int i) { return gimme_blind_b3(i); }
int gimme_blind_b3(int i) { return gimme_blind_b4(i); }
int gimme_blind_b4(int i) { return g_blinded + i; }

// This function should alway trigger the creation of a new blinded
// variant of need_blinded_var!
//
// CHECK-LABEL: define {{.*}} @sanityCheck
// CHECK-LABEL: define {{.*}} @need_blind_var{{\.[a-z0-9]+}}(
int sanityCheck() {
  return need_blind_var(g_blinded);
}