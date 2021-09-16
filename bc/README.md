# Blinded Computation compiler support

The main branch of the project is `bc/main`, let's try to keep this stable
(i.e., such that it compiles and project specific tests pass). 

## Coding standards and git best practices 

Follow the [LLVM Coding Standards], this not only makes the code "look nicer".
This makes the code nicer to read. More importantly, it helps to oneself to read
all the LLVM code base itself.


### Git commits

Short commits are okay, it is often useful to try to make each commit a small
self-contained change. This also makes it easier to write a short descriptive
commit message, which you should do. That said, these are just guidelines, so no
need to go to extremes in order to split commits up.

### Git branches

As general guidance, always work in "personal" branches (for instance, all my
work is always in `hans/*` branches, or for this project, in `hans/bc/*`
branches). I recommend using a personal main branch (e.g., `hans/bc/main`) for
stable work, this is then easy to merge into `bc/main` when stable while more
experimental stuff can be kept elsewhere. Consequently, you should never work on
"other people's" branches; instead, always create your own branch to work on and
test other stuff (e.g., in my case I would create
`hans/bc/messing-up-hossams-stuff`, or something like that).

## Building LLVM

I recommend using a `build/bc` subdirectory for builds related to this project.
This is also assumed by some helper script in the [/bc] folder of the project.

The main branch we are using is `bc/main`.

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
  ../../llvm
```

Consult [LLVM docs on CMake] for details. In particular, adjust
`LLVM_PARALLEL_{LINK,COMPILE}_JOBS` to suit your build environment (link jobs
can be very memory intensive, and should be limited to avoid out-of-memory
exceptions). Installing (`ninja install`) is typically not needed, but if
needed, the install location is controlled with `CMAKE_INSTALL_PREFIX`.

## Project structure

On a high-level, the compiler work consists of an analysis pass, various
transformations, and a verification pass.

### TaintTrackingAnalysis

- [/llvm/include/llvm/Analysis/TaintTracking.h]
- [/llvm/lib/Analysis/TaintTracking.cpp]

This is an inter-procedural analysis that produces the set of `Value`s that are
tainted by taint sinks (e.g., tainted global values or tainted function
arguments).

### BlindedInstrConversionPass

- [/llvm/include/llvm/Transforms/BlindedComputation/BlindedInstrConversion.h]
- [/llvm/lib/Transforms/BlindedComputation/BlindedInstrConversion.cpp]

This pass tries to transform code structures that violate the blinding policy
such that they conform to the policy.  It uses the TaintTrackingAnalysis pass to
figure out which values are tainted. At present, it does two main
transformations:

1) It converts blinded array indexes to a safe variant that avoids
   data-dependent memory accesses.  
2) It automatically generates new functions to
   accommodate argument permutations that include blinded values.

### BlindedDataUsageAnalysis

- [/llvm/include/llvm/Analysis/BlindedDataUsage.h]
- [/llvm/lib/Analysis/BlindedDataUsage.cpp]

This is a simple analysis pass that uses the TaintTrackingAnalysis pass to find
taints and then validates all instructions to ensure they do not violate the
blinded value use policies.

## Tests

For this project we have a bunch of tests that can be run using:

```sh
ninja check-llvm-blindedcomputation
```

This should be populated with tests for fixed bugs, added features, etc; and
also used to verify that we don't introduce regressions when working on the
project.

### Writing tests

Test for **llvm-lit** can be written in many ways, including:

1) Writing plain IR by hand. (Use the [LLVM IR reference] to help out!)
2) Generating IR from C/C++ using **clang**.
3) Extracting test from existing programs using **clang**, **llvm-extract**, or
   **llvm-reduce**.

Tests can be run using the **llvm-lit** tool or via the build system. For
instance, to run all tests under [/llvm/test/BlindedComputation], one can run:

```sh
ninja check-llvm-blindedcomputation
```

The tests themselves are typically composed of IR source files with `RUN` and
different `CHECK` directives. The `RUN` directive tells the runner how to
execute the source file, whereas the `CHECK` directives tell the **FileCheck**
utility what to expect in the output ([LLVM docs on FileCheck]).

For instance [/llvm/test/BlindedComputation/Analysis/tainttracking-printer.ll]
starts with the following `RUN` directive:

```llvm
; RUN: opt -passes="print<taint-tracking>" -S -disable-output < %s 2>&1 | FileCheck %s
```

Here, the `RUN` tells **llvm-lit** to run the **opt** tool on the current input
file (the `%s` is automatically replaced with a path to the current file, `-S`
causes the IR to be input/output as human-readable text, and the
`-disable-output` disables IR output and instead only outputs the results of the
analysis). This output is then piped to **FileCheck**, which uses the current
input file to find `CHECK` directives that it compares to the output of **opt**.

Tests are mostly silent and only output diagnostics and details on failure.
Failure output also includes the exact commands executed, which often is useful
in debugging. For instance, to see the output of the **opt** command in the
above test, one can run something like:

```sh
"$BUILD_DIRECTORY"/bin/opt -passes="print<taint-tracking>" -S -disable-output < "$SOURCE_DIRECTORY"/llvm/test/BlindedComputation/Analysis/tainttracking-printer.ll 2>&1
```

Side note: Tests can me marked as expected to fail by adding the following line
after the `RUN` directives:

```llvm
; XFAIL: *
```

This is useful for adding tests that are known to fail, but that need to be
fixed and help in illustrating a bug or missing feature.

### Creating tests

To generate IR from a C/C++ source file, one can use `clang -emit-llvm -S -c` to
compile the source file. The `-emit-llvm` tells clang to dump the IR, and the
`-S` tells clang to dump the IR in a human-readable textual format. Probably
also enable optimizations with `-O1` to make the IR easier to read (this, for
instance, removes many unnecessary memory store/load operations that).

```sh
# To produce LLVM IR from source file
cd "$BUILD_DIRECTORY"
./bin/clang -emit-llvm -O1 -S -c "$TEST".c
cat test_code.ll
./bin/opt -passes=print<taint-tracking> -S -disable-output < "$TEST".ll
```

When encountering bugs in real programs, it is useful to extract those as tests.
This can be done using **llvm-extract** or **llvm-reduce**. Extract is a simpler
tool and simply extracts a given function, which might or might not be
sufficient to replicate a bug. Reduce is a more advanced tool that allows a test
case to be gradually reduced to a smaller test case that still triggers the bug
under consideration (there is a good LLVM Dev Meeting video on it
[LLVM Dev Meeting talk on llvm-reduce])

#### Possible "helper" scripts

The [/bc/llvm-test] folder contains some helpers scripts to generate tests from
C/C++ source files. These can be compiled with **make**, and automatically
installed under [/llvm/test] by running `make install`. The basic idea here is
to write the test in a C/C++ source file which is then automatically converted
to the corresponding IR test case. If this is used, I recommend starting with
only building and inspecting the files (i.e., not using install automatically).

---

[LLVM docs on FileCheck]: https://llvm.org/docs/CommandGuide/FileCheck.html
[LLVM IR reference]: https://llvm.org/docs/LangRef.html
[LLVM docs on CMake]: https://llvm.org/docs/CMake.html
[LLVM Dev Meeting talk on llvm-reduce]: https://www.youtube.com/watch?v=n1jDj7J9N8c
[LLVM Coding Standards]: https://llvm.org/docs/CodingStandards.html

[/bc]:           https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/bc
[/bc/llvm-test]: https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/bc/llvm-test

[/llvm/test]:https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/test
[/llvm/test/BlindedComputation]: https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/test/BlindedComputation
[/llvm/test/BlindedComputation/Analysis/TaintTracking/tainttracking-printer.ll]: https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/test/BlindedComputation/Analysis/tainttracking-printer.ll

[/llvm/include/llvm/Analysis/BlindedDataUsage.h]: https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/include/llvm/Analysis/BlindedDataUsage.h
[/llvm/include/llvm/Analysis/TaintTracking.h]:    https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/include/llvm/Analysis/TaintTracking.h
[/llvm/lib/Analysis/BlindedDataUsage.cpp]:        https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/lib/Analysis/BlindedDataUsage.cpp
[/llvm/lib/Analysis/TaintTracking.cpp]:           https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/lib/Analysis/TaintTracking.cpp
[/llvm/include/llvm/Transforms/BlindedComputation/BlindedInstrConversion.h]: https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/include/llvm/Transforms/BlindedComputation/BlindedInstrConversion.h
[/llvm/lib/Transforms/BlindedComputation/BlindedInstrConversion.cpp]: https://gitlab.com/ssg-research/platsec/attack-tolerant-execution/bc-llvm/-/tree/bc/main/llvm/lib/Transforms/BlindedComputation/BlindedInstrConversion.cpp
