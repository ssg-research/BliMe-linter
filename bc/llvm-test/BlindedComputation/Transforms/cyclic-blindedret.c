// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s


/*
This test tests the taint propagation through return value in a cyclic call graph.
A --->    B  ---> D ---> E
|     |      |           |
--< --C      <-----------
*/



#include <stdio.h>

#define noinline __attribute__((noinline))
#define blinded __attribute__((blinded))

int sink;
blinded int global_ret_blnd;
int func_A(int non_blnd, blinded int blnd);
int func_B(int non_blnd, blinded int blnd);
int func_C(int non_blnd, blinded int blnd);
int func_D(int non_blnd, blinded int blnd);
int func_E(int non_blnd, blinded int blnd);

// CHECK-DAG: call i32 @func_SELF({{.*}}), {{.*}} !my.md.blinded
noinline int func_SELF(unsigned int non_blnd, blinded int blnd) {
    if (non_blnd == 0) {
        printf("%d", non_blnd);
        return blnd;
    }
    sink += non_blnd;
    func_SELF(non_blnd + sink, blnd);
    printf("%d", non_blnd);
}

// CHECK-DAG: call i32 @func_B(i32 1, i32 2), {{.*}} !my.md.blinded
noinline int func_A(blinded int blnd, int non_blnd) {
    printf("%d %d", blnd, non_blnd);
    int blinded_r = func_B(1, 2);
    return global_ret_blnd;
}


// CHECK-DAG: call i32 @func_C(i32 3, i32 4), {{.*}} !my.md.blinded
// CHECK-DAG: call i32 @func_D(i32 7, i32 8), {{.*}} !my.md.blinded
noinline int func_B(int non_blnd, blinded int blnd) {
    printf("%d %d", blnd, non_blnd);
    int blinded_r = func_C(3, 4);
    int blinded_r_2 = func_D(7, 8);
    return global_ret_blnd;
}

// CHECK-DAG: call i32 @func_A(i32 5, i32 6), {{.*}} !my.md.blinded
noinline int func_C(int non_blnd, blinded int blnd) {
    printf("%d %d", blnd, non_blnd);
    int blinded_r = func_A(5, 6);
    return global_ret_blnd;
}

// CHECK-DAG: call i32 @func_E(i32 9, i32 10), {{.*}} !my.md.blinded
noinline int func_D(int non_blnd, blinded int blnd) {
    printf("%d %d", blnd, non_blnd);
    int blinded_r = func_E(9, 10);
    return global_ret_blnd;
}

// CHECK-DAG: call i32 @func_B(i32 11, i32 12), {{.*}} !my.md.blinded
noinline int func_E(int non_blnd, blinded int blnd) {
    printf("%d %d", blnd, non_blnd);
    int blinded_r = func_B(11, 12);
    return global_ret_blnd;
}
// int use_blnd(blinded int blnd_arg) {
// 	int non_blnd = 7;
// 	blnd_a(blnd_arg, &non_blnd);
//     int to_ret = non_blnd + 10;
// 	return to_ret;
// }

int main() {
    func_A(5, 7);
    func_SELF(2, 15);
    return 0;
}