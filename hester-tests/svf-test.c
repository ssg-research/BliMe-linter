#include <stdio.h>
#define __noinline __attribute__((noinline))

__attribute__((noinline)) int add_nums(int a, int b) {
    int d = 18;
    return a + d;
}

__attribute__((noinline)) int test_alias(int a, int b) {
    int* c = &a;
    int* d = c;
    *c = b;
    return *d;
}

// __attribute__((noinline)) int test_mult_ptr(int*** q) {
    
//     return ***q + 17;
// }

__attribute__((noinline)) int test_cond(int cond, int idx) {
    int arr[12] = {1,2,3};
    int arr2[12] = {0};

    for (int i = 0; i < 10; i++) {
        arr[i] += idx;
        arr2[i] -= cond;
    }
    return (cond > 5 ? arr : arr2)[idx];
}

int main() {
    int a = 10, b = 15;
    int* q1 = &a;
    int** q2 = &q1;
    int*** q3 = &q2;
    int c = add_nums(a, b);
    int d = test_alias(a, b);
    int e = test_cond(b, a);
    printf("%d%d%d", c, d, e);
    return 0;
}