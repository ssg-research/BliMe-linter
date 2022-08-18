#include <stdio.h>

#define noinline __attribute__((noinline))
#define blinded __attribute__((blinded))

blinded int globalBlinded = 12;

int blnd_a(int a, int* b) {
	*b = a;
	return a;
}

void blnd_b(blinded int* q) {
  *q = globalBlinded;
}

void blnd_c(blinded int* q) {
  *q = 15;
}

// non_blnd update when returning from blnd_a
int use_blnd(blinded int blnd_arg) {
	int non_blnd = 7;
	blnd_a(blnd_arg, &non_blnd);
  int to_ret = non_blnd + 10;
	return to_ret;
}

int main() {
    int non_blnd_b, non_blnd_c;
    int used = use_blnd(15);

    blnd_b(&non_blnd_b);
    blnd_c(&non_blnd_c);
    printf("%d", use_blnd(15));
    return 0;
}