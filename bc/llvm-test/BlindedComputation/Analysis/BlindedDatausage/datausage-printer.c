// RUN: opt -passes="print<blinded-data-usage>" -S -disable-output < %s 2>&1 | FileCheck %s

#include <stddef.h>

int do_conditional(__attribute__((blinded)) int cond) {
  return cond > 10 ? 1 : 0;
}

int do_load(int *arr, __attribute__((blinded)) size_t idx) {
  return arr[idx];
}
