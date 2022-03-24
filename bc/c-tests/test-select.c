#include "common.h"
#include <stdio.h>
#include <stdlib.h>


int g_cond = 12;

int get_value1() { return g_cond; }
int get_value2() { return g_cond + 3; }

__noinline
int simpleTest1(__blinded int cond, int a, int b) {
  return cond > 11 ? a : b;
}

__noinline
int simpleTest2(__blinded int cond, int a) {
  return cond > g_cond ? a : 0;
}

__noinline
int simpleTest3(__blinded int cond, int (*a)(), int (*b)()) {
  int (*func)() = cond > g_cond ? a : b;
  return func();
}

__noinline
int simpleTest(int a, int b, int c) {
  printf("%d", simpleTest1(a, b, c));

  for (int i = 0; i < 10; ++i) {
    g_cond = (i + a);
    printf("%d", simpleTest2(b, c));
  }

  for (int i = 0; i < 10; ++i) {
    g_cond = (i + a);
    printf("%d", simpleTest3(b, &get_value1, &get_value2));
  }

  printf("\n");
  return 0;
}

int main(int argc, char **argv) {
  if (argc == 4) {
    simpleTest(atoi(argv[1]), atoi(argv[2]), atoi(argv[3]));
    return 0;
  }

  if (argc == 3) {
    simpleTest(atoi(argv[1]), atoi(argv[2]), 7);
    return 0;
  }

  if (argc == 2) {
    simpleTest(atoi(argv[1]), 3, 5);
    return 0;
  }

  simpleTest(11, 13, 17);
  return 0;
}
