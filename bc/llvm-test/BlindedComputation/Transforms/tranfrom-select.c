// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// XFAIL: *

// CHECK-LABEL: @simpleTest
// CHECK-NOT: select
// CHECK: ret i32
int simpleTest(__attribute__((blinded)) int a) {
  return a > 11 ? 45 : 78;
}