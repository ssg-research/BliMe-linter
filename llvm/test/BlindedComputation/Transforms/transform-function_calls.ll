; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; //
; This doesn't currently do much useful things, the idea would be to test how
; explicit return value blinding affects things, but that isn't currently
; implemented.
; 
; #define noinline __attribute__((noinline))
; #define blinded __attribute__((blinded))
; 
; blinded int g_arr[10];
; blinded int g_blinded = 0;
; 
; int get_blinded_undefined(int i);
; 
; CHECK-LABEL: @get_blinded_defined
; blinded noinline int get_blinded_defined(int i) {
; noinline int get_blinded_defined(int i) {
;   return g_arr[i] + g_blinded;
; }
; 
; CHECK-LABEL: @test_defined
; CHECK: call{{.*}}@get_blinded_defined.1
; int test_defined(blinded int a) {
;   int l_blinded = g_blinded;
;   return get_blinded_defined(l_blinded);
; }
; 
; CHECK-LABEL: @test_undefined
; int test_undefined(blinded int a) {
;   int l_blinded = g_blinded;
;   return get_blinded_undefined(l_blinded);
; }



; ModuleID = 'BlindedComputation/Transforms/transform-function_calls.c'
source_filename = "BlindedComputation/Transforms/transform-function_calls.c"
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

@g_blinded = dso_local local_unnamed_addr global i32 0, align 4, !dbg !0 #0
@g_arr = dso_local local_unnamed_addr global [10 x i32] zeroinitializer, align 16, !dbg !6 #0

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @get_blinded_defined(i32 %i) local_unnamed_addr #1 !dbg !16 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !20, metadata !DIExpression()), !dbg !21
  %idxprom = sext i32 %i to i64, !dbg !22
  %arrayidx = getelementptr inbounds [10 x i32], [10 x i32]* @g_arr, i64 0, i64 %idxprom, !dbg !22
  %0 = load i32, i32* %arrayidx, align 4, !dbg !22, !tbaa !23
  %1 = load i32, i32* @g_blinded, align 4, !dbg !27, !tbaa !23
  %add = add nsw i32 %1, %0, !dbg !28
  ret i32 %add, !dbg !29
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @test_defined(i32 blinded %a) local_unnamed_addr #2 !dbg !30 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !32, metadata !DIExpression()), !dbg !34
  %0 = load i32, i32* @g_blinded, align 4, !dbg !35, !tbaa !23
  call void @llvm.dbg.value(metadata i32 %0, metadata !33, metadata !DIExpression()), !dbg !34
  %call = tail call i32 @get_blinded_defined(i32 %0), !dbg !36
  ret i32 %call, !dbg !37
}

; Function Attrs: nounwind uwtable
define dso_local i32 @test_undefined(i32 blinded %a) local_unnamed_addr #3 !dbg !38 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !40, metadata !DIExpression()), !dbg !42
  %0 = load i32, i32* @g_blinded, align 4, !dbg !43, !tbaa !23
  call void @llvm.dbg.value(metadata i32 %0, metadata !41, metadata !DIExpression()), !dbg !42
  %call = tail call i32 @get_blinded_undefined(i32 %0) #6, !dbg !44
  ret i32 %call, !dbg !45
}

declare !dbg !46 dso_local i32 @get_blinded_undefined(i32) local_unnamed_addr #4

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #5

attributes #0 = { blinded }
attributes #1 = { noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nounwind readnone speculatable willreturn }
attributes #6 = { nounwind }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!12, !13, !14}
!llvm.ident = !{!15}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "g_blinded", scope: !2, file: !3, line: 11, type: !9, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/transform-function_calls.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!4 = !{}
!5 = !{!0, !6}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "g_arr", scope: !2, file: !3, line: 10, type: !8, isLocal: false, isDefinition: true)
!8 = !DICompositeType(tag: DW_TAG_array_type, baseType: !9, size: 320, elements: !10)
!9 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!10 = !{!11}
!11 = !DISubrange(count: 10)
!12 = !{i32 7, !"Dwarf Version", i32 4}
!13 = !{i32 2, !"Debug Info Version", i32 3}
!14 = !{i32 1, !"wchar_size", i32 4}
!15 = !{!"clang version 11.0.0"}
!16 = distinct !DISubprogram(name: "get_blinded_defined", scope: !3, file: !3, line: 17, type: !17, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !19)
!17 = !DISubroutineType(types: !18)
!18 = !{!9, !9}
!19 = !{!20}
!20 = !DILocalVariable(name: "i", arg: 1, scope: !16, file: !3, line: 17, type: !9)
!21 = !DILocation(line: 0, scope: !16)
!22 = !DILocation(line: 18, column: 10, scope: !16)
!23 = !{!24, !24, i64 0}
!24 = !{!"int", !25, i64 0}
!25 = !{!"omnipotent char", !26, i64 0}
!26 = !{!"Simple C/C++ TBAA"}
!27 = !DILocation(line: 18, column: 21, scope: !16)
!28 = !DILocation(line: 18, column: 19, scope: !16)
!29 = !DILocation(line: 18, column: 3, scope: !16)
!30 = distinct !DISubprogram(name: "test_defined", scope: !3, file: !3, line: 23, type: !17, scopeLine: 23, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !31)
!31 = !{!32, !33}
!32 = !DILocalVariable(name: "a", arg: 1, scope: !30, file: !3, line: 23, type: !9)
!33 = !DILocalVariable(name: "l_blinded", scope: !30, file: !3, line: 24, type: !9)
!34 = !DILocation(line: 0, scope: !30)
!35 = !DILocation(line: 24, column: 19, scope: !30)
!36 = !DILocation(line: 25, column: 10, scope: !30)
!37 = !DILocation(line: 25, column: 3, scope: !30)
!38 = distinct !DISubprogram(name: "test_undefined", scope: !3, file: !3, line: 29, type: !17, scopeLine: 29, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !39)
!39 = !{!40, !41}
!40 = !DILocalVariable(name: "a", arg: 1, scope: !38, file: !3, line: 29, type: !9)
!41 = !DILocalVariable(name: "l_blinded", scope: !38, file: !3, line: 30, type: !9)
!42 = !DILocation(line: 0, scope: !38)
!43 = !DILocation(line: 30, column: 19, scope: !38)
!44 = !DILocation(line: 31, column: 10, scope: !38)
!45 = !DILocation(line: 31, column: 3, scope: !38)
!46 = !DISubprogram(name: "get_blinded_undefined", scope: !3, file: !3, line: 13, type: !17, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !4)
