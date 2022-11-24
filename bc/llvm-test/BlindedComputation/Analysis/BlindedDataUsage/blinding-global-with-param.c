// RUN: opt -passes="print<blinded-data-usage>" -S -disable-output < %s 2>&1 | FileCheck %s

#include <stddef.h>

#define noinline __attribute__((noinline))

int out;

noinline void move_blinded(__attribute__((blinded)) int blinded_in) {
	out =  blinded_in;
}

// CHECK: loadInstr with a blinded pointer!
// CHECK: %2 = load i8, i8* %arrayidx1
int main(int argc, char **argv) {
	move_blinded(argc);
	
	return argv[0][argc + out];
}