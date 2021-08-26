#include <stdio.h>

__attribute__((blinded)) int val = 5;
// int val = 5;

extern int transform(int num);

int isPositiveAfterTransform(int num) {
	if (transform(num) > 0) { // return of `transform(num)` should be tainted so this should not compile
		return 1;
	} else {
		return 0;
	}
}

int main() {
	printf("%d\n", isPositiveAfterTransform(val));
	return 0;
}
