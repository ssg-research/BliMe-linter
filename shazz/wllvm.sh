# run `pip install wllvm` first

# output .ll
# LLVM_COMPILER=clang LLVM_COMPILER_PATH=$(pwd)/../build/bin/ wllvm -fexperimental-new-pass-manager -S -emit-llvm wllvm_demo_1.c wllvm_demo_2.c

# output executable
LLVM_COMPILER=clang LLVM_COMPILER_PATH=$(pwd)/../build/bin/ wllvm -fexperimental-new-pass-manager wllvm_demo_1.c wllvm_demo_2.c -o wllvm_demo
# LLVM_COMPILER=clang LLVM_COMPILER_PATH=$(pwd)/../build/bin/ wllvm -fexperimental-new-pass-manager wllvm_demo_1.c -o wllvm_demo
