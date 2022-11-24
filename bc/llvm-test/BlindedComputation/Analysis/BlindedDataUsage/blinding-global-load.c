// RUN: opt -passes="print<blinded-data-usage>" -S -disable-output < %s 2>&1 | FileCheck %s

#include <stddef.h>

#define noinline __attribute__((noinline))

int out;
__attribute__((blinded)) int blinded_in;

noinline void move_blinded(void) {
	out =  blinded_in;
}

// CHECK: loadInstr with a blinded pointer!
// CHECK: %2 = load i8, i8* %arrayidx1
int main(int argc, char **argv) {
	move_blinded();
	
	return argv[0][argc + out];
}