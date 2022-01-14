// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// #include <stdint.h>

// CHECK-LABEL: @simpleTest
// CHECK-NOT: select
// CHECK: ret float
float simpleTest(__attribute__((blinded)) int a, float b, float c) {
  return a > 11 ? b : c;
}
