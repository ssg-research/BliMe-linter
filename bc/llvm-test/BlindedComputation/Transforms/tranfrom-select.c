// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
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

char *moarTricky(__attribute__((blinded)) int a, char *b, char *c) {
  return a > 11 ? b : c;
}

// Lets just ignore this...
int get_number(int *);

// CHECK-LABEL: @arrayMess
// CHECK-NOT: select
// CHECK: ret i32
int arrayMess(__attribute__((blinded)) int cond) {
  int a[10] = {1,2,3,4,5,6,7,8,9,0};
  int b[10] = {0,9,8,7,6,5,4,3,2,1};

  int *param = cond > 10 ? a : b;

  return get_number(param);
}

// CHECK-LABEL: @arrayMess2
// CHECK-NOT: select
// CHECK: ret i32
int arrayMess2(__attribute__((blinded)) int cond, int mod, int idx) {
  int a[10] = {1,2,3,4,5,6,7,8,9,0};
  int b[10] = {0,9,8,7,6,5,4,3,2,1};

  for (int i = 0; i < 10; ++i) {
    a[i] += mod;
    b[i] -= mod;
  }

  return (cond > 10 ? a : b)[idx];
}

struct failWhale { long d1; long d2; long d3; };

// CHECK-LABEL: @structMesser
// CHECK-NOT: select
// CHECK: ret
struct failWhale structMesser(__attribute__((blinded)) int cond,
                              struct failWhale a, struct failWhale b) {
  return cond > 10 ? a : b;
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
