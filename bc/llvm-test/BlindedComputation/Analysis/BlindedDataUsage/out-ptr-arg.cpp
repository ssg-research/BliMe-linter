// COM: RUN: opt -passes="print<taint-tracking>" -S -disable-output < %s 2>&1 | FileCheck %s

#include <stddef.h>

__attribute__((blinded)) int *in;

void process(int *out, __attribute__((blinded)) int *in, int size) {
	for(int i = 0; i < size; ++i) {
		out[i] = in[i];
	}
}

// CHECK-DAG: BlindedComputation/Analysis/BlindedDataUsage/datausage-printer.c:21
void caller() {
	in = new int[5];
	for (int i = 0; i < 5; ++i) {
		in[i] = i+1;
	}
	int out[5] = {0};

	process(out, in, 3);
}