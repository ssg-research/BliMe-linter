; RUN: opt -passes="print<blinded-data-usage>" -S -disable-output < %s 2>&1 | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; XFAIL: *
; 
; FIXME: Add proper CHECK directives and remove XFAIL when working
; 
; #include <stddef.h>
; 
; Dummy func declarations to prevent compiler from getting too smart
; void do_stuff1();
; void do_stuff2();
; 
; CHECK: We expect to see one failure due to conditional on blinded data!
; void do_conditional(__attribute__((blinded)) int cond) {
;   if (cond > 10) {
;     do_stuff1();
;   } else {
;     do_stuff2();
;   }
; }
; 
; CHECK: We expect another failure here due to the indexing!
; int do_load(int *arr, __attribute__((blinded)) size_t idx) {
;   return arr[idx];
; }



; ModuleID = 'BlindedComputation/Analysis/BlindedDataUsage/datausage-printer.c'
source_filename = "BlindedComputation/Analysis/BlindedDataUsage/datausage-printer.c"
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

; Function Attrs: nounwind uwtable
define dso_local void @do_conditional(i32 blinded %cond) local_unnamed_addr #0 !dbg !7 {
entry:
  call void @llvm.dbg.value(metadata i32 %cond, metadata !12, metadata !DIExpression()), !dbg !13
  %cmp = icmp sgt i32 %cond, 10, !dbg !14
  br i1 %cmp, label %if.then, label %if.else, !dbg !16

if.then:                                          ; preds = %entry
  tail call void (...) @do_stuff1() #4, !dbg !17
  br label %if.end, !dbg !19

if.else:                                          ; preds = %entry
  tail call void (...) @do_stuff2() #4, !dbg !20
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  ret void, !dbg !22
}

declare !dbg !23 dso_local void @do_stuff1(...) local_unnamed_addr #1

declare !dbg !26 dso_local void @do_stuff2(...) local_unnamed_addr #1

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @do_load(i32* nocapture readonly %arr, i64 blinded %idx) local_unnamed_addr #2 !dbg !27 {
entry:
  call void @llvm.dbg.value(metadata i32* %arr, metadata !35, metadata !DIExpression()), !dbg !37
  call void @llvm.dbg.value(metadata i64 %idx, metadata !36, metadata !DIExpression()), !dbg !37
  %arrayidx = getelementptr inbounds i32, i32* %arr, i64 %idx, !dbg !38
  %0 = load i32, i32* %arrayidx, align 4, !dbg !38, !tbaa !39
  ret i32 %0, !dbg !43
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }
attributes #4 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4, !5}
!llvm.ident = !{!6}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "BlindedComputation/Analysis/BlindedDataUsage/datausage-printer.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!2 = !{}
!3 = !{i32 7, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = !{i32 1, !"wchar_size", i32 4}
!6 = !{!"clang version 11.0.0"}
!7 = distinct !DISubprogram(name: "do_conditional", scope: !1, file: !1, line: 13, type: !8, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!8 = !DISubroutineType(types: !9)
!9 = !{null, !10}
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !{!12}
!12 = !DILocalVariable(name: "cond", arg: 1, scope: !7, file: !1, line: 13, type: !10)
!13 = !DILocation(line: 0, scope: !7)
!14 = !DILocation(line: 14, column: 12, scope: !15)
!15 = distinct !DILexicalBlock(scope: !7, file: !1, line: 14, column: 7)
!16 = !DILocation(line: 14, column: 7, scope: !7)
!17 = !DILocation(line: 15, column: 5, scope: !18)
!18 = distinct !DILexicalBlock(scope: !15, file: !1, line: 14, column: 18)
!19 = !DILocation(line: 16, column: 3, scope: !18)
!20 = !DILocation(line: 17, column: 5, scope: !21)
!21 = distinct !DILexicalBlock(scope: !15, file: !1, line: 16, column: 10)
!22 = !DILocation(line: 19, column: 1, scope: !7)
!23 = !DISubprogram(name: "do_stuff1", scope: !1, file: !1, line: 9, type: !24, spFlags: DISPFlagOptimized, retainedNodes: !2)
!24 = !DISubroutineType(types: !25)
!25 = !{null, null}
!26 = !DISubprogram(name: "do_stuff2", scope: !1, file: !1, line: 10, type: !24, spFlags: DISPFlagOptimized, retainedNodes: !2)
!27 = distinct !DISubprogram(name: "do_load", scope: !1, file: !1, line: 22, type: !28, scopeLine: 22, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !34)
!28 = !DISubroutineType(types: !29)
!29 = !{!10, !30, !31}
!30 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !10, size: 64)
!31 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !32, line: 46, baseType: !33)
!32 = !DIFile(filename: "build/bc/lib/clang/11.0.0/include/stddef.h", directory: "/home/ishkamiel/d/llvm")
!33 = !DIBasicType(name: "long unsigned int", size: 64, encoding: DW_ATE_unsigned)
!34 = !{!35, !36}
!35 = !DILocalVariable(name: "arr", arg: 1, scope: !27, file: !1, line: 22, type: !30)
!36 = !DILocalVariable(name: "idx", arg: 2, scope: !27, file: !1, line: 22, type: !31)
!37 = !DILocation(line: 0, scope: !27)
!38 = !DILocation(line: 23, column: 10, scope: !27)
!39 = !{!40, !40, i64 0}
!40 = !{!"int", !41, i64 0}
!41 = !{!"omnipotent char", !42, i64 0}
!42 = !{!"Simple C/C++ TBAA"}
!43 = !DILocation(line: 23, column: 3, scope: !27)
