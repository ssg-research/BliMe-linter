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

CFLAGS = -g -fPIE -static -O2
TRANSFROM_CFLAGS = -fexperimental-new-pass-manager

SOURCE_FILES = $(wildcard *.c)
SOURCE_FILES += $(wildcard */*.c)

T_OUT_FILES    = $(SOURCE_FILES:.c=.t)
P_OUT_FILES    = $(SOURCE_FILES:.c=.p)
LL_FILES       = $(SOURCE_FILES:.c=.ll)
TEST_NAMES= $(SOURCE_FILES:.c=)

all: $(T_OUT_FILES) $(P_OUT_FILES) $(LL_FILES)

ll: $(LL_FILES)

test: $(TEST_NAMES)

.PHONY: $(TEST_NAMES)
$(TEST_NAMES): % : %.t %.p
	./test_inputs.sh $@

$(T_OUT_FILES): %.t : %.c
	$(CC) $(CFLAGS) $(TRANSFROM_CFLAGS) $< -o $@

$(P_OUT_FILES): %.p : %.c
	$(CC) $(CFLAGS) $< -o $@

$(LL_FILES): %.ll : %.c
	$(CC) $(CFLAGS) -emit-llvm -S -c $< -o $@

.PHONY: clean
clean:
	rm $(T_OUT_FILES) $(P_OUT_FILES) $(LL_FILES)

print-%: ; @echo $* = $($*)

# $(CC) -fexperimental-new-pass-manager -c -g -fPIE -static $< -o $@
