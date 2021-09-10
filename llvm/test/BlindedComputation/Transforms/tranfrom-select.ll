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
; CHECK: ret i32
; int simpleTest(__attribute__((blinded)) int a) {
;   return a > 11 ? 45 : 78;
; }
; 
; CHECK-LABEL: @varReturns
; CHECK-NOT: select
; CHECK: ret i32
; int varReturns(__attribute__((blinded)) int a, int b, int c) {
;   return a > 11 ? b : c;
; }
; 
; CHECK-LABEL: @moarTricky
; CHECK-NOT: select
; CHECK: ret i8*
; char *moarTricky(__attribute__((blinded)) int a, char *b, char *c) {
;   return a > 11 ? b : c;
; }
; 
; void test1(uintptr_t);
; void test2(intptr_t);
; 
; CHECK-LABEL: @moarTricky2
; CHECK-NOT: select
; CHECK: ret i8*
; char *moarTricky2(__attribute__((blinded)) int a,
;                  __attribute__((blinded)) int cond, char *b, char *c) {
;   test1((uintptr_t) b);
;   test2((intptr_t) b);
;   return a > cond ? b : c;
; }



; ModuleID = 'BlindedComputation/Transforms/tranfrom-select.c'
source_filename = "BlindedComputation/Transforms/tranfrom-select.c"
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
define dso_local i32 @simpleTest(i32 blinded %a) local_unnamed_addr #0 !dbg !13 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !18, metadata !DIExpression()), !dbg !19
  %cmp = icmp sgt i32 %a, 11, !dbg !20
  %cond = select i1 %cmp, i32 45, i32 78, !dbg !21
  ret i32 %cond, !dbg !22
}

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i32 @varReturns(i32 blinded %a, i32 %b, i32 %c) local_unnamed_addr #0 !dbg !23 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !27, metadata !DIExpression()), !dbg !30
  call void @llvm.dbg.value(metadata i32 %b, metadata !28, metadata !DIExpression()), !dbg !30
  call void @llvm.dbg.value(metadata i32 %c, metadata !29, metadata !DIExpression()), !dbg !30
  %cmp = icmp sgt i32 %a, 11, !dbg !31
  %cond = select i1 %cmp, i32 %b, i32 %c, !dbg !32
  ret i32 %cond, !dbg !33
}

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i8* @moarTricky(i32 blinded %a, i8* readnone %b, i8* readnone %c) local_unnamed_addr #0 !dbg !34 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !40, metadata !DIExpression()), !dbg !43
  call void @llvm.dbg.value(metadata i8* %b, metadata !41, metadata !DIExpression()), !dbg !43
  call void @llvm.dbg.value(metadata i8* %c, metadata !42, metadata !DIExpression()), !dbg !43
  %cmp = icmp sgt i32 %a, 11, !dbg !44
  %cond = select i1 %cmp, i8* %b, i8* %c, !dbg !45
  ret i8* %cond, !dbg !46
}

; Function Attrs: nounwind uwtable
define dso_local i8* @moarTricky2(i32 blinded %a, i32 blinded %cond, i8* %b, i8* readnone %c) local_unnamed_addr #1 !dbg !47 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !51, metadata !DIExpression()), !dbg !55
  call void @llvm.dbg.value(metadata i32 %cond, metadata !52, metadata !DIExpression()), !dbg !55
  call void @llvm.dbg.value(metadata i8* %b, metadata !53, metadata !DIExpression()), !dbg !55
  call void @llvm.dbg.value(metadata i8* %c, metadata !54, metadata !DIExpression()), !dbg !55
  %0 = ptrtoint i8* %b to i64, !dbg !56
  tail call void @test1(i64 %0) #4, !dbg !57
  tail call void @test2(i64 %0) #4, !dbg !58
  %cmp = icmp sgt i32 %a, %cond, !dbg !59
  %cond1 = select i1 %cmp, i8* %b, i8* %c, !dbg !60
  ret i8* %cond1, !dbg !61
}

declare !dbg !62 dso_local void @test1(i64) local_unnamed_addr #2

declare !dbg !65 dso_local void @test2(i64) local_unnamed_addr #2

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }
attributes #4 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!9, !10, !11}
!llvm.ident = !{!12}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, retainedTypes: !3, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "BlindedComputation/Transforms/tranfrom-select.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!2 = !{}
!3 = !{!4, !7}
!4 = !DIDerivedType(tag: DW_TAG_typedef, name: "uintptr_t", file: !5, line: 90, baseType: !6)
!5 = !DIFile(filename: "/usr/include/stdint.h", directory: "")
!6 = !DIBasicType(name: "long unsigned int", size: 64, encoding: DW_ATE_unsigned)
!7 = !DIDerivedType(tag: DW_TAG_typedef, name: "intptr_t", file: !5, line: 87, baseType: !8)
!8 = !DIBasicType(name: "long int", size: 64, encoding: DW_ATE_signed)
!9 = !{i32 7, !"Dwarf Version", i32 4}
!10 = !{i32 2, !"Debug Info Version", i32 3}
!11 = !{i32 1, !"wchar_size", i32 4}
!12 = !{!"clang version 11.0.0"}
!13 = distinct !DISubprogram(name: "simpleTest", scope: !1, file: !1, line: 7, type: !14, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !17)
!14 = !DISubroutineType(types: !15)
!15 = !{!16, !16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18}
!18 = !DILocalVariable(name: "a", arg: 1, scope: !13, file: !1, line: 7, type: !16)
!19 = !DILocation(line: 0, scope: !13)
!20 = !DILocation(line: 8, column: 12, scope: !13)
!21 = !DILocation(line: 8, column: 10, scope: !13)
!22 = !DILocation(line: 8, column: 3, scope: !13)
!23 = distinct !DISubprogram(name: "varReturns", scope: !1, file: !1, line: 14, type: !24, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !26)
!24 = !DISubroutineType(types: !25)
!25 = !{!16, !16, !16, !16}
!26 = !{!27, !28, !29}
!27 = !DILocalVariable(name: "a", arg: 1, scope: !23, file: !1, line: 14, type: !16)
!28 = !DILocalVariable(name: "b", arg: 2, scope: !23, file: !1, line: 14, type: !16)
!29 = !DILocalVariable(name: "c", arg: 3, scope: !23, file: !1, line: 14, type: !16)
!30 = !DILocation(line: 0, scope: !23)
!31 = !DILocation(line: 15, column: 12, scope: !23)
!32 = !DILocation(line: 15, column: 10, scope: !23)
!33 = !DILocation(line: 15, column: 3, scope: !23)
!34 = distinct !DISubprogram(name: "moarTricky", scope: !1, file: !1, line: 21, type: !35, scopeLine: 21, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !39)
!35 = !DISubroutineType(types: !36)
!36 = !{!37, !16, !37, !37}
!37 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !38, size: 64)
!38 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!39 = !{!40, !41, !42}
!40 = !DILocalVariable(name: "a", arg: 1, scope: !34, file: !1, line: 21, type: !16)
!41 = !DILocalVariable(name: "b", arg: 2, scope: !34, file: !1, line: 21, type: !37)
!42 = !DILocalVariable(name: "c", arg: 3, scope: !34, file: !1, line: 21, type: !37)
!43 = !DILocation(line: 0, scope: !34)
!44 = !DILocation(line: 22, column: 12, scope: !34)
!45 = !DILocation(line: 22, column: 10, scope: !34)
!46 = !DILocation(line: 22, column: 3, scope: !34)
!47 = distinct !DISubprogram(name: "moarTricky2", scope: !1, file: !1, line: 31, type: !48, scopeLine: 32, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !50)
!48 = !DISubroutineType(types: !49)
!49 = !{!37, !16, !16, !37, !37}
!50 = !{!51, !52, !53, !54}
!51 = !DILocalVariable(name: "a", arg: 1, scope: !47, file: !1, line: 31, type: !16)
!52 = !DILocalVariable(name: "cond", arg: 2, scope: !47, file: !1, line: 32, type: !16)
!53 = !DILocalVariable(name: "b", arg: 3, scope: !47, file: !1, line: 32, type: !37)
!54 = !DILocalVariable(name: "c", arg: 4, scope: !47, file: !1, line: 32, type: !37)
!55 = !DILocation(line: 0, scope: !47)
!56 = !DILocation(line: 33, column: 9, scope: !47)
!57 = !DILocation(line: 33, column: 3, scope: !47)
!58 = !DILocation(line: 34, column: 3, scope: !47)
!59 = !DILocation(line: 35, column: 12, scope: !47)
!60 = !DILocation(line: 35, column: 10, scope: !47)
!61 = !DILocation(line: 35, column: 3, scope: !47)
!62 = !DISubprogram(name: "test1", scope: !1, file: !1, line: 25, type: !63, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!63 = !DISubroutineType(types: !64)
!64 = !{null, !6}
!65 = !DISubprogram(name: "test2", scope: !1, file: !1, line: 26, type: !66, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!66 = !DISubroutineType(types: !67)
!67 = !{null, !8}
