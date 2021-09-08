// RUN: opt -passes="print<blinded-data-usage>" -S -disable-output < %s 2>&1 | FileCheck %s
// XFAIL: *

// FIXME: Add proper CHECK directives and remove XFAIL when working

#include <stddef.h>

// Dummy func declarations to prevent compiler from getting too smart
void do_stuff1();
void do_stuff2();

// CHECK: We expect to see one failure due to conditional on blinded data!
void do_conditional(__attribute__((blinded)) int cond) {
  if (cond > 10) {
    do_stuff1();
  } else {
    do_stuff2();
  }
}

// CHECK: We expect another failure here due to the indexing!
int do_load(int *arr, __attribute__((blinded)) size_t idx) {
  return arr[idx];
}
