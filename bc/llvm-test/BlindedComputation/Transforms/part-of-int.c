#include <stdio.h>

// This should 
int arrayMess2(__attribute__((blinded)) int cond, int mod, int idx1, int idx2) {
  int index = mod % 4;
  char select_cond = ((char*)(&cond))[index];
  printf("%c", select_cond);

  return 0;
}