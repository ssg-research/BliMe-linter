__attribute__((blinded)) int blinded = 5;

int isPositiveAfterTransform(int num) {
	if (transform(num) > 0) { // return of `transform(num)` should be tainted so this should not compile
		return 1;
	} else {
		return 0;
	}
}

int main() {
	printf("%d\n", isPositiveAfterTransform(blinded));
}
