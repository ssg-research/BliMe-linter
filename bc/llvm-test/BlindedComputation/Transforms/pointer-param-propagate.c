// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// XFAIL: *

#include <stdio.h>

#define noinline __attribute__((noinline))
#define blinded __attribute__((blinded))

blinded int globalBlinded = 12;

noinline int blnd_a(int a, int* b) {
	*b = a;
	return a;
}

noinline void blnd_b(blinded int* q) {
  *q = 15;
}

noinline int use_blnd_a(blinded int blnd_arg) {
	int non_blnd = 7;

  // will propagate blnd_arg to the non_blnd pointer
	blnd_a(blnd_arg, &non_blnd);

  // the braching based on the value of non_blnd will be tainted
  return non_blnd;
}

noinline int use_blnd_b(int* normal_arg) {
  blnd_b(normal_arg);
  if (*normal_arg > 0) {
    return 12;
  }
  else {
    return 10;
  }
}

int main() {
    int non_blnd_b = 10, non_blnd_c;
    // a: the parameter is not blinded. But tainted inside.
    // b: the parameter is blinded, though the input pointer is overwritten
    //    by a non-sensitive value.
    int used_a = use_blnd_a(15);
    int used_b = use_blnd_b(&non_blnd_b);
    printf("%d, %d", used_a, used_b);

    return 0;
}