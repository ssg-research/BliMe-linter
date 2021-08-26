#include "blind.h"

void blnd(unsigned char *buffer, unsigned long long numbytes) {
	asm volatile (
		"blnd %[ptr], %[size]"
		:: [ptr]"r"(buffer), [size]"r"(numbytes)
	);
}

void rblnd() {
	asm volatile (
		"rblnd"
		::
	);
}