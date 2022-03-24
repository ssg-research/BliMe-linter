#include "common.h"
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#define SEED 1234
#define A_LEN 100

__noinline
void modify_array(intptr_t *arr, size_t len) {
  for (int i = 0; i <len; ++i) { arr[i] = rand(); }
}

__noinline
intptr_t sanityCheck(__blinded intptr_t blinded_i) {
  intptr_t a[10] = {1,2,3,4,5,6,7,8,9,0};
  modify_array(a, 10); // Make sure the compiler cannot know what a contains!
  return a[blinded_i % 10];
}

__noinline
void simpleTest(__blinded int a) {
  intptr_t arr[A_LEN];
  modify_array(arr, A_LEN);

  for (intptr_t i = 0; i < A_LEN; ++i) {
    printf ("%lu", arr[(a + i) % A_LEN]);
  }
}

int main(int argc, char **argv) {
  srand(argc > 1 ? atoi(argv[1]) : 1234);

  printf("%ld", sanityCheck(rand()));

  simpleTest(argc > 2 ? atoi(argv[2]) : rand());

  return 0;
}
