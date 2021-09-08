#ifndef __COMMON_TEST_HEADER_H_
#define __COMMON_TEST_HEADER_H_

#include <string.h>
#include <stdint.h>
#include <stdio.h>

void leak(char *ptr);
void doNothingCharPP(char **ptr);
void doNothingIntPP(int32_t **ptr);
void doNothingCharP(char *ptr);
void doNothingIntP(int32_t *ptr);

#define aarch64_clobber_all_regs() asm volatile("" : : : "x0","x1","x2","x3","x4","x5","x6","x7","x8","x9","x10","x11","x12","x13","x14","x15","x17","x18","x19","x20","x21","x22","x23","x24","x25","x26","x27","x28","x29","x30");

#endif // __COMMON_TEST_HEADER_H_
