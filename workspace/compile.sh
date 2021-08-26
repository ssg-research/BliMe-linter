# # run `pip install wllvm` first

rm -rf *.o *.s *.ll *.bc *.out

# create bitcode file for each module
../build/bin/clang -target riscv64-unknown-linux-gnu -fexperimental-new-pass-manager -mfloat-abi=hard -c -g -static -emit-llvm demo.c randombytes.c tweetnacl.c &&

# link all bitcode files into one
../build/bin/llvm-link demo.bc randombytes.bc tweetnacl.bc -o linked.bc &&

# run pass on the single bitcode file
../build/bin/opt -passes="blinded-instr-conv" --march=riscv64 --mtriple="riscv64-unknown-linux-gnu" --mcpu=generic-rv64 --float-abi=hard --relocation-model=static linked.bc > final.bc &&

# generate object file from final bitcode file
../build/bin/llc -O0 --march=riscv64 --mtriple="riscv64-unknown-linux-gnu" --mcpu=generic-rv64 --float-abi=hard --relocation-model=static --target-abi=lp64d --filetype=obj final.bc -o final.o &&

echo "Generated object file final.o"
