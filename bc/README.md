# Blinded Computation compiler support

## Building LLVM

The bc/llvm-test scrits assume builds under build/bc. To set this up, got to the repository root and execute:

```sh
mkdir -p build/bc
cd build/bc
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE:STRING=Debug \
  -DCMAKE_INSTALL_PREFIX:FILEPATH="${HOME}/opt/llvm/bc" \
  -DLLVM_TARGETS_TO_BUILD:STRING=X86;RISCV \
  -DLLVM_ENABLE_PROJECTS:STRING=clang \
  -DLLVM_CCACHE_BUILD:BOOL=On \
  -DLLVM_OPTIMIZED_TABLEGEN:BOOL=On \
  -DCMAKE_CXX_STANDARD:STRING=14 \
  -DBUILD_SHARED_LIBS:BOOL=On \
  -DLLVM_BUILD_TOOLS:BOOL=Off \
  -DLLVM_PARALLEL_LINK_JOBS:STRING=4 \
  -DLLVM_PARALLEL_COMPILE_JOBS:STRING=8 \
  ..
```

Consult [LLVM-CMake] for details. In particular, adjust
`LLVM_PARALLEL_{LINK,COMPILE}_JOBS` to suit your build environment (link jobs
can be very memory intensive, and should be limited to avoid out-of-memory
exceptions). Installing (`ninja install`) is typically not needed, but if
needed, the install location is controlled with `CMAKE_INSTALL_PREFIX`.

## Tests

Test for `llvm-lit` can be written in many ways, including: 1) Just writing
plain IR, 2) generating IR from C/C++ or 3) by extracting tests from existing
programs. Tests can be run using the `llvm-lit` tool or by running `ninja
check-llvm-blindedcomputation`, or a similar `check-*` target.

A test is structured as a source file with one or more `RUN` commands and subsequent `CHECK` directives. A Typical test looks something like the following:

```llvm
; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
```

Here, the run tells `llvm-lit` to run the `opt` tool on the current input file
(the `%s` is automatically replaced with a path to the current file). The output
of `opt` is then piped to `FileCheck`, which again uses the current input file
to find `CHECK` directives that it compares to the output of `opt`.

### Creating tests

To generate IR from a C/C++ source file, one can use `clang -emit-llvm -S -c` to
compile the source file. The `-emit-llvm` tells clang to dump the IR, and the
`-S` tells clang to dump the IR in a human-readable textual format.

The `bc/llvm-test` folder contains some helpers scripts to generate tests from
C/C++ source files. These can be compiled with make, and installed to the
appropriate test directory using `make install`.

When encountering bugs in real programs, it is useful to extract those as tests.
Thttps://www.youtube.com/watch?v=n1jDj7J9N8chis can be done using `llvm-extract`
or `llvm-reduce`. Extract is a simpler tool and simply extracts a given
function, which might or might not be sufficient to replicate a bug. Reduce is a
more advanced tool that allows a test case to be gradually reduced to a smaller
test case that still triggers the bug under consideration (there is a good LLVM
Dev Meeting video on it [LLVMDev-reduce])


[LLVM-FileCheck]: https://llvm.org/docs/CommandGuide/FileCheck.html
[LLVM-IR]: https://llvm.org/docs/LangRef.html
[LLVM-CMake]: https://llvm.org/docs/CMake.html
[LLVMDev-reduce]: https://www.youtube.com/watch?v=n1jDj7J9N8c
