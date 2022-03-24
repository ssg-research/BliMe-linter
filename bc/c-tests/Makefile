#
# Author: Hans Liljestrand <hans@liljestrand.dev>
#
# Distributed under Apache License v2.0 with LLVM Exceptions.

#######################################################################
# To configure BUILD_DIR, create a Makefile.local and override there! #
#######################################################################
-include Makefile.local

LLVM_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../llvm)
BUILD_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../build/bc)

CC = $(BUILD_DIR)/bin/clang
OPT = $(BUILD_DIR)/bin/opt

CFLAGS = -g -fPIE -static -O2
TRANSFROM_CFLAGS = -fexperimental-new-pass-manager
# -mllvm -passes="blinded-instr-conv"

SOURCE_FILES = $(wildcard *.c)
SOURCE_FILES += $(wildcard */*.c)

T_OUT_FILES    = $(SOURCE_FILES:.c=.t)
P_OUT_FILES    = $(SOURCE_FILES:.c=.p)
G_OUT_FILES    = $(SOURCE_FILES:.c=.g)
OPT_OUT_FILES    = $(SOURCE_FILES:.c=.opt)
LL_FILES_T     = $(SOURCE_FILES:.c=.t.ll)
LL_FILES_P     = $(SOURCE_FILES:.c=.p.ll)
LL_FILES_OPT     = $(SOURCE_FILES:.c=.opt.ll)
LL_FILES       = $(LL_FILES_P) $(LL_FILES_T) $(LL_FILES_OPT)

TEST_NAMES= $(SOURCE_FILES:.c=)

all: $(T_OUT_FILES) $(P_OUT_FILES) $(LL_FILES) $(G_OUT_FILES) $(OPT_OUT_FILES)

ll: $(LL_FILES)

test: $(TEST_NAMES)

.PHONY: $(TEST_NAMES)
$(TEST_NAMES): % : %.t %.p %.g
	./test_inputs.sh $@

$(T_OUT_FILES): %.t : %.c
	$(CC) $(CFLAGS) $(TRANSFROM_CFLAGS) $< -o $@

$(P_OUT_FILES): %.p : %.c
	$(CC) $(CFLAGS) -DNO_BLINDED $< -o $@

$(G_OUT_FILES): %.g : %.c
	gcc $(CFLAGS) -DNO_BLINDED $< -o $@

$(LL_FILES_P): %.p.ll : %.c
	$(CC) $(CFLAGS) -emit-llvm -S $< -o $@

$(LL_FILES_T): %.t.ll : %.c
	$(CC) $(CFLAGS) $(TRANSFROM_CFLAGS) -emit-llvm -S $< -o $@

$(LL_FILES_OPT): %.opt.ll : %.p.ll
	$(OPT) -passes="blinded-instr-conv" -S < $<  > $@

$(OPT_OUT_FILES): % : %.ll
	$(CC) $< -o $@

.PHONY: clean
clean:
	rm -f $(T_OUT_FILES) $(P_OUT_FILES) $(LL_FILES) $(G_OUT_FILES) $(OPT_OUT_FILES)

print-%: ; @echo $* = $($*)
