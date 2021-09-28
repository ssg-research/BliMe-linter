// RUN: opt -passes="print<blinded-data-usage>" -S -disable-output < %s 2>&1 | FileCheck %s

#include <stddef.h>

// Dummy func declarations to prevent compiler from getting too smart
void do_stuff1();
void do_stuff2();

// CHECK-DAG: BlindedComputation/Analysis/BlindedDataUsage/datausage-printer.c:12:7

void do_conditional(__attribute__((blinded)) int cond) {
  if (cond > 10) {
    do_stuff1();
  } else {
    do_stuff2();
  }
}

// CHECK-DAG: BlindedComputation/Analysis/BlindedDataUsage/datausage-printer.c:21
int do_load(int *arr, __attribute__((blinded)) size_t idx) {
  return arr[idx];
}
