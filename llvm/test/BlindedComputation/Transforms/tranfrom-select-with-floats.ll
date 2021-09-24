; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; #include <stdint.h>
; 
; CHECK-LABEL: @simpleTest
; CHECK-NOT: select
; CHECK: ret float
; float simpleTest(__attribute__((blinded)) int a, float b, float c) {
;   return a > 11 ? b : c;
; }



; ModuleID = 'BlindedComputation/Transforms/tranfrom-select-with-floats.c'
source_filename = "BlindedComputation/Transforms/tranfrom-select-with-floats.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64"

define dso_local void @doNothingCharPP(i8** nocapture) {
  ret void
}

define dso_local void @doNothingIntPP(i32** nocapture) {
  ret void
}

define dso_local void @doNothingCharP(i8* nocapture) {
  ret void
}

define dso_local void @doNothingIntP(i32* nocapture) {
  ret void
}

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local float @simpleTest(i32 blinded %a, float %b, float %c) local_unnamed_addr #0 !dbg !7 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !13, metadata !DIExpression()), !dbg !16
  call void @llvm.dbg.value(metadata float %b, metadata !14, metadata !DIExpression()), !dbg !16
  call void @llvm.dbg.value(metadata float %c, metadata !15, metadata !DIExpression()), !dbg !16
  %cmp = icmp sgt i32 %a, 11, !dbg !17
  %cond = select i1 %cmp, float %b, float %c, !dbg !18
  ret float %cond, !dbg !19
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4, !5}
!llvm.ident = !{!6}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "BlindedComputation/Transforms/tranfrom-select-with-floats.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!2 = !{}
!3 = !{i32 7, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = !{i32 1, !"wchar_size", i32 4}
!6 = !{!"clang version 11.0.0"}
!7 = distinct !DISubprogram(name: "simpleTest", scope: !1, file: !1, line: 7, type: !8, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !12)
!8 = !DISubroutineType(types: !9)
!9 = !{!10, !11, !10, !10}
!10 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!11 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!12 = !{!13, !14, !15}
!13 = !DILocalVariable(name: "a", arg: 1, scope: !7, file: !1, line: 7, type: !11)
!14 = !DILocalVariable(name: "b", arg: 2, scope: !7, file: !1, line: 7, type: !10)
!15 = !DILocalVariable(name: "c", arg: 3, scope: !7, file: !1, line: 7, type: !10)
!16 = !DILocation(line: 0, scope: !7)
!17 = !DILocation(line: 8, column: 12, scope: !7)
!18 = !DILocation(line: 8, column: 10, scope: !7)
!19 = !DILocation(line: 8, column: 3, scope: !7)
