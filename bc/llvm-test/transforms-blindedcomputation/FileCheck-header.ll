; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
