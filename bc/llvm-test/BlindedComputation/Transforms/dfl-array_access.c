// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s --check-prefixes=CHKALL,CHECK
// RUN: opt -O1 -S < %s | FileCheck %s --check-prefixes=CHKALL,NOINSTR
#include <stdint.h>

void modify_array(intptr_t *);

// CHECK-LABEL: @blinded_access
// CHECK: call void @modify_array
// NOINSTR: getelementptr inbounds [10 x i64], [10 x i64]* %a, i64 0, i64 %blinded_i
// CHECK-NOT: getelementptr inbounds [10 x i64], [10 x i64]* %a, i64 0, i64 %blinded_i
// CHECK: ret i64
intptr_t blinded_access(__attribute__((blinded)) intptr_t blinded_i) {
  intptr_t a[10] = {1,2,3,4,5,6,7,8,9,0};

  // Make sure the compiler cannot know what a contains!
  modify_array(a);

  return a[blinded_i];
}
