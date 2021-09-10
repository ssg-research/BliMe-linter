// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// XFAIL: *
#include <stdint.h>

// CHECK-LABEL: @simpleTest
// CHECK-NOT: select
// CHECK: ret i32
int simpleTest(__attribute__((blinded)) int a) {
  return a > 11 ? 45 : 78;
}

// CHECK-LABEL: @varReturns
// CHECK-NOT: select
// CHECK: ret i32
int varReturns(__attribute__((blinded)) int a, int b, int c) {
  return a > 11 ? b : c;
}

// CHECK-LABEL: @moarTricky
// CHECK-NOT: select
// CHECK: ret i8*
char *moarTricky(__attribute__((blinded)) int a, char *b, char *c) {
  return a > 11 ? b : c;
}

void test1(uintptr_t);
void test2(intptr_t);

// CHECK-LABEL: @moarTricky2
// CHECK-NOT: select
// CHECK: ret i8*
char *moarTricky2(__attribute__((blinded)) int a,
                 __attribute__((blinded)) int cond, char *b, char *c) {
  test1((uintptr_t) b);
  test2((intptr_t) b);
  return a > cond ? b : c;
}
