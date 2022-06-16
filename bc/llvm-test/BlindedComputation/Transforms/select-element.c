// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// #include <stdint>

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

  return cond > 10 ? a[idx] : b[idx];
}