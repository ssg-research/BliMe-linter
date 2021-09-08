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

INSTALL_DIR ?= $(LLVM_DIR)/test/
CFLAGS ?= --target=x86_64 
CFLAGS += -Wall -O2
CFLAGS += -Xclang -disable-lifetime-markers 
CFLAGS += -fno-discard-value-names 
CFLAGS += -fno-unroll-loops
CFLAGS += -gdwarf

SOURCE_FILES = $(filter-out common.c,$(wildcard *.c))
SOURCE_FILES += $(wildcard */*.c)
SOURCE_FILES += $(wildcard */*/*.c)
SOURCE_FILES += $(wildcard */*/*/*.c)
TEST_FILES   = $(SOURCE_FILES:.c=.ll)
LL_FILES     = $(SOURCE_FILES:.c=.c.ll)
HEADER_FILES = $(SOURCE_FILES:.c=.c.header)
BODY_FILES = $(SOURCE_FILES:.c=.c.body)
OBJ_FILES    = $(SOURCE_FILES:.c=.o)
OUT_FILES    = $(SOURCE_FILES:.c=.out)
INSTALL_FILES = $(addprefix $(INSTALL_DIR), $(TEST_FILES))

all: $(TEST_FILES)

COMMON_DEPS = common.ll common.h FileCheck-header.ll Makefile
TMP_FILES = $(BODY_FILES) $(HEADER_FILES) $(LL_FILES)

$(TEST_FILES): %.ll : %.c %.c.body %.c.header %.c.ll $(COMMON_DEPS) 
	@cat $<.header $<.body > $@

$(HEADER_FILES): %.c.header : %.c
	@./gen_header.sh -cflags "$(CFLAGS)" -i $< > $@

$(BODY_FILES): %.c.body : %.c.ll
	@./gen_body.sh -i $< > $@

$(LL_FILES): %.c.ll : %.c Makefile
	$(CC) $(CFLAGS) -emit-llvm -c -S $< -o $@

$(OUT_FILES): %.out : %.c
	$(CC) $(CFLAGS) $^ -o $@

$(OBJ_FILES): %.o : %.c
	$(CC) $(CFLAGS) -c $^ -o $@

install: $(INSTALL_FILES)

$(INSTALL_FILES): $(INSTALL_DIR)% : %
	@mkdir -p $(dir $(INSTALL_DIR)$<)
	cp $< $(INSTALL_DIR)$<

.PHONY: clean
clean:
	rm -rf $(TMP_FILES)

.PHONY: dist-clean
dist-clean:
	rm -rf $(TMP_FILES) $(TEST_FILES) $(OUT_FILES) $(OBJ_FILES)

print-%: ; @echo $* = $($*)

.PHONY: dump-vars
dump-vars: print-LLVM_DIR print-BUILD_DIR print-INSTALL_DIR print-CC

# vim:ft=make
