#! /usr/bin/env bash

set -e -u -o pipefail

LLVM_COMPILER_PATH="/home/x34duan/compiler/bc-llvm/build/bc/bin/"
CLANG_PATH="${LLVM_COMPILER_PATH}/clang"
OPT_PATH="${LLVM_COMPILER_PATH}/opt"
LLVMAS_PATH="${LLVM_COMPILER_PATH}/llvm-as"
LLVMDIS_PATH="${LLVM_COMPILER_PATH}/llvm-dis"


# Generate IR
# TODOs: generate RISCV-64 object
${CLANG_PATH} -emit-llvm -S -c test_constantine.c -o test_constantine.ll

# Apply change passes
# blinded-instr-conv
${OPT_PATH} -passes="blinded-instr-conv" -S < test_constantine.ll -o test_constantine.conv.ll

# modify-metadata
${OPT_PATH} -passes="metadata-modify" -S < test_constantine.conv.ll -o test_constantine.mod.ll

# Generate bitcode
${LLVMAS_PATH} test_constantine.mod.ll -o test_constantine.bc

# copy all the files to constantine directory
cp test_constantine.c /home/x34duan/constantine/src/
cp test_constantine.bc /home/x34duan/constantine/src/

# run constantine in the container
docker exec flamboyant_nash sh -c "cd /wrkdir/constantine/src && python3 ./constantine_copy.py -O1 ./test_constantine.c -o test_constantine.out"

# move files back into build directory
mv /home/x34duan/constantine/src/test_constantine.final.bc .
${LLVMDIS_PATH} test_constantine.final.bc -o test_constantine.final.ll
