rm -rf *.bc *.o *.out

# create bitcode file for each module
../../build/bin/clang -fexperimental-new-pass-manager -c -g -fPIE -static -emit-llvm file1.c file2.c &&

# link all bitcode files into one
../../build/bin/llvm-link file1.bc file2.bc -o linked.bc &&

# run pass on the single bitcode file
../../build/bin/opt -passes="blinded-instr-conv" linked.bc > final.bc &&

# generate object file from final bitcode file
../../build/bin/llc -filetype=obj final.bc -o final.o &&

# generate executable from object file
../../build/bin/clang final.o -o final.out &&

echo "Compiled to exectuable final.out"


