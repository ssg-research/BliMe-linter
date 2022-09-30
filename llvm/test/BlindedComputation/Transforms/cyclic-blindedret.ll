; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -I/usr/include/x86_64-linux-gnu -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; 
; 
; /*
; This test tests the taint propagation through return value in a cyclic call graph.
; A --->    B  ---> D ---> E
; |     |      |           |
; --< --C      <-----------
; */
; 
; 
; 
; #include <stdio.h>
; 
; #define noinline __attribute__((noinline))
; #define blinded __attribute__((blinded))
; 
; blinded int global_ret_blnd;
; int func_A(int non_blnd, blinded int blnd);
; int func_B(int non_blnd, blinded int blnd);
; int func_C(int non_blnd, blinded int blnd);
; int func_D(int non_blnd, blinded int blnd);
; int func_E(int non_blnd, blinded int blnd);
; 
; int func_SELF(unsigned int non_blnd, blinded int blnd) {
;     if (non_blnd == 0) {
;         printf("%d", non_blnd);
;         return blnd;
;     }
;     return func_SELF(non_blnd - 1, blnd);
; }
; 
; CHECK-DAG: call i32 @func_B(i32 1, i32 2), !my.md.blinded
; int func_A(blinded int blnd, int non_blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_B(1, 2);
;     return global_ret_blnd;
; }
; 
; 
; CHECK-DAG: call i32 @func_C(i32 3, i32 4), !my.md.blinded
; CHECK-DAG: call i32 @func_D(i32 7, i32 8), !my.md.blinded
; int func_B(int non_blnd, blinded int blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_C(3, 4);
;     int blinded_r_2 = func_D(7, 8);
;     return global_ret_blnd;
; }
; 
; CHECK-DAG: call i32 @func_A(i32 5, i32 6), !my.md.blinded
; int func_C(int non_blnd, blinded int blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_A(5, 6);
;     return global_ret_blnd;
; }
; 
; CHECK-DAG: call i32 @func_E(i32 9, i32 10), !my.md.blinded
; int func_D(int non_blnd, blinded int blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_E(9, 10);
;     return global_ret_blnd;
; }
; 
; CHECK-DAG: call i32 @func_B(i32 11, i32 12), !my.md.blinded
; int func_E(int non_blnd, blinded int blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_B(11, 12);
;     return global_ret_blnd;
; }
; int use_blnd(blinded int blnd_arg) {
; 	int non_blnd = 7;
; 	blnd_a(blnd_arg, &non_blnd);
;     int to_ret = non_blnd + 10;
; 	return to_ret;
; }
; 
; int main() {
;     func_A(5, 7);
;     func_SELF(2, 15);
;     return 0;
; }



; ModuleID = 'BlindedComputation/Transforms/cyclic-blindedret.c'
source_filename = "BlindedComputation/Transforms/cyclic-blindedret.c"
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

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@.str.1 = private unnamed_addr constant [6 x i8] c"%d %d\00", align 1
@global_ret_blnd = dso_local local_unnamed_addr global i32 0, align 4, !dbg !0 #0

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @func_SELF(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !11 {
entry:
  call void @llvm.dbg.value(metadata i32 undef, metadata !16, metadata !DIExpression()), !dbg !18
  call void @llvm.dbg.value(metadata i32 undef, metadata !17, metadata !DIExpression()), !dbg !18
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([3 x i8], [3 x i8]* @.str, i64 0, i64 0), i32 0), !dbg !19
  ret i32 %blnd, !dbg !22
}

; Function Attrs: nofree nounwind
declare dso_local i32 @printf(i8* nocapture readonly, ...) local_unnamed_addr #2

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @func_A(i32 blinded %blnd, i32 %non_blnd) local_unnamed_addr #1 !dbg !23 {
entry:
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !27, metadata !DIExpression()), !dbg !30
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !28, metadata !DIExpression()), !dbg !30
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !31
  %call1 = tail call i32 @func_B(i32 1, i32 2), !dbg !32
  call void @llvm.dbg.value(metadata i32 %call1, metadata !29, metadata !DIExpression()), !dbg !30
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !33, !tbaa !34
  ret i32 %0, !dbg !38
}

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @func_B(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !39 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !41, metadata !DIExpression()), !dbg !45
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !42, metadata !DIExpression()), !dbg !45
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !46
  call void @llvm.dbg.value(metadata i32 3, metadata !47, metadata !DIExpression()) #4, !dbg !52
  call void @llvm.dbg.value(metadata i32 4, metadata !50, metadata !DIExpression()) #4, !dbg !52
  %call.i = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 4, i32 3) #4, !dbg !54
  call void @llvm.dbg.value(metadata i32 5, metadata !27, metadata !DIExpression()) #4, !dbg !55
  call void @llvm.dbg.value(metadata i32 6, metadata !28, metadata !DIExpression()) #4, !dbg !55
  %call.i.i = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 5, i32 6) #4, !dbg !57
  %call1.i.i = tail call i32 @func_B(i32 1, i32 2) #4, !dbg !58
  call void @llvm.dbg.value(metadata i32 %call1.i.i, metadata !29, metadata !DIExpression()) #4, !dbg !55
  call void @llvm.dbg.value(metadata i32 undef, metadata !51, metadata !DIExpression()) #4, !dbg !52
  call void @llvm.dbg.value(metadata i32 undef, metadata !43, metadata !DIExpression()), !dbg !45
  call void @llvm.dbg.value(metadata i32 7, metadata !59, metadata !DIExpression()) #4, !dbg !64
  call void @llvm.dbg.value(metadata i32 8, metadata !62, metadata !DIExpression()) #4, !dbg !64
  %call.i3 = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 8, i32 7) #4, !dbg !66
  call void @llvm.dbg.value(metadata i32 9, metadata !67, metadata !DIExpression()) #4, !dbg !72
  call void @llvm.dbg.value(metadata i32 10, metadata !70, metadata !DIExpression()) #4, !dbg !72
  %call.i.i4 = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 10, i32 9) #4, !dbg !74
  %call1.i.i5 = tail call i32 @func_B(i32 11, i32 12) #4, !dbg !75
  call void @llvm.dbg.value(metadata i32 %call1.i.i5, metadata !71, metadata !DIExpression()) #4, !dbg !72
  call void @llvm.dbg.value(metadata i32 undef, metadata !63, metadata !DIExpression()) #4, !dbg !64
  call void @llvm.dbg.value(metadata i32 undef, metadata !44, metadata !DIExpression()), !dbg !45
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !76, !tbaa !34
  ret i32 %0, !dbg !77
}

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @func_C(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !48 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !47, metadata !DIExpression()), !dbg !78
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !50, metadata !DIExpression()), !dbg !78
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !79
  call void @llvm.dbg.value(metadata i32 5, metadata !27, metadata !DIExpression()) #4, !dbg !80
  call void @llvm.dbg.value(metadata i32 6, metadata !28, metadata !DIExpression()) #4, !dbg !80
  %call.i = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 5, i32 6) #4, !dbg !82
  %call1.i = tail call i32 @func_B(i32 1, i32 2) #4, !dbg !83
  call void @llvm.dbg.value(metadata i32 %call1.i, metadata !29, metadata !DIExpression()) #4, !dbg !80
  call void @llvm.dbg.value(metadata i32 undef, metadata !51, metadata !DIExpression()), !dbg !78
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !84, !tbaa !34
  ret i32 %0, !dbg !85
}

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @func_D(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !60 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !59, metadata !DIExpression()), !dbg !86
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !62, metadata !DIExpression()), !dbg !86
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !87
  call void @llvm.dbg.value(metadata i32 9, metadata !67, metadata !DIExpression()) #4, !dbg !88
  call void @llvm.dbg.value(metadata i32 10, metadata !70, metadata !DIExpression()) #4, !dbg !88
  %call.i = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 10, i32 9) #4, !dbg !90
  %call1.i = tail call i32 @func_B(i32 11, i32 12) #4, !dbg !91
  call void @llvm.dbg.value(metadata i32 %call1.i, metadata !71, metadata !DIExpression()) #4, !dbg !88
  call void @llvm.dbg.value(metadata i32 undef, metadata !63, metadata !DIExpression()), !dbg !86
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !92, !tbaa !34
  ret i32 %0, !dbg !93
}

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @func_E(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !68 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !67, metadata !DIExpression()), !dbg !94
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !70, metadata !DIExpression()), !dbg !94
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !95
  %call1 = tail call i32 @func_B(i32 11, i32 12), !dbg !96
  call void @llvm.dbg.value(metadata i32 %call1, metadata !71, metadata !DIExpression()), !dbg !94
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !97, !tbaa !34
  ret i32 %0, !dbg !98
}

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #1 !dbg !99 {
entry:
  call void @llvm.dbg.value(metadata i32 5, metadata !27, metadata !DIExpression()) #4, !dbg !102
  call void @llvm.dbg.value(metadata i32 7, metadata !28, metadata !DIExpression()) #4, !dbg !102
  %call.i = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 5, i32 7) #4, !dbg !104
  %call1.i = tail call i32 @func_B(i32 1, i32 2) #4, !dbg !105
  call void @llvm.dbg.value(metadata i32 %call1.i, metadata !29, metadata !DIExpression()) #4, !dbg !102
  call void @llvm.dbg.value(metadata i32 undef, metadata !16, metadata !DIExpression()) #4, !dbg !106
  call void @llvm.dbg.value(metadata i32 undef, metadata !17, metadata !DIExpression()) #4, !dbg !106
  %call.i2 = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([3 x i8], [3 x i8]* @.str, i64 0, i64 0), i32 0) #4, !dbg !108
  ret i32 0, !dbg !109
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { blinded }
attributes #1 = { nofree nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }
attributes #4 = { nounwind }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!7, !8, !9}
!llvm.ident = !{!10}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "global_ret_blnd", scope: !2, file: !3, line: 18, type: !6, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/cyclic-blindedret.c", directory: "")
!4 = !{}
!5 = !{!0}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = !{i32 7, !"Dwarf Version", i32 4}
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 1, !"wchar_size", i32 4}
!10 = !{!"clang version 11.0.0"}
!11 = distinct !DISubprogram(name: "func_SELF", scope: !3, file: !3, line: 26, type: !12, scopeLine: 26, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !15)
!12 = !DISubroutineType(types: !13)
!13 = !{!6, !14, !6}
!14 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!15 = !{!16, !17}
!16 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !11, file: !3, line: 26, type: !14)
!17 = !DILocalVariable(name: "blnd", arg: 2, scope: !11, file: !3, line: 26, type: !6)
!18 = !DILocation(line: 0, scope: !11)
!19 = !DILocation(line: 28, column: 9, scope: !20)
!20 = distinct !DILexicalBlock(scope: !21, file: !3, line: 27, column: 24)
!21 = distinct !DILexicalBlock(scope: !11, file: !3, line: 27, column: 9)
!22 = !DILocation(line: 32, column: 1, scope: !11)
!23 = distinct !DISubprogram(name: "func_A", scope: !3, file: !3, line: 35, type: !24, scopeLine: 35, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !26)
!24 = !DISubroutineType(types: !25)
!25 = !{!6, !6, !6}
!26 = !{!27, !28, !29}
!27 = !DILocalVariable(name: "blnd", arg: 1, scope: !23, file: !3, line: 35, type: !6)
!28 = !DILocalVariable(name: "non_blnd", arg: 2, scope: !23, file: !3, line: 35, type: !6)
!29 = !DILocalVariable(name: "blinded_r", scope: !23, file: !3, line: 37, type: !6)
!30 = !DILocation(line: 0, scope: !23)
!31 = !DILocation(line: 36, column: 5, scope: !23)
!32 = !DILocation(line: 37, column: 21, scope: !23)
!33 = !DILocation(line: 38, column: 12, scope: !23)
!34 = !{!35, !35, i64 0}
!35 = !{!"int", !36, i64 0}
!36 = !{!"omnipotent char", !37, i64 0}
!37 = !{!"Simple C/C++ TBAA"}
!38 = !DILocation(line: 38, column: 5, scope: !23)
!39 = distinct !DISubprogram(name: "func_B", scope: !3, file: !3, line: 44, type: !24, scopeLine: 44, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !40)
!40 = !{!41, !42, !43, !44}
!41 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !39, file: !3, line: 44, type: !6)
!42 = !DILocalVariable(name: "blnd", arg: 2, scope: !39, file: !3, line: 44, type: !6)
!43 = !DILocalVariable(name: "blinded_r", scope: !39, file: !3, line: 46, type: !6)
!44 = !DILocalVariable(name: "blinded_r_2", scope: !39, file: !3, line: 47, type: !6)
!45 = !DILocation(line: 0, scope: !39)
!46 = !DILocation(line: 45, column: 5, scope: !39)
!47 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !48, file: !3, line: 52, type: !6)
!48 = distinct !DISubprogram(name: "func_C", scope: !3, file: !3, line: 52, type: !24, scopeLine: 52, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !49)
!49 = !{!47, !50, !51}
!50 = !DILocalVariable(name: "blnd", arg: 2, scope: !48, file: !3, line: 52, type: !6)
!51 = !DILocalVariable(name: "blinded_r", scope: !48, file: !3, line: 54, type: !6)
!52 = !DILocation(line: 0, scope: !48, inlinedAt: !53)
!53 = distinct !DILocation(line: 46, column: 21, scope: !39)
!54 = !DILocation(line: 53, column: 5, scope: !48, inlinedAt: !53)
!55 = !DILocation(line: 0, scope: !23, inlinedAt: !56)
!56 = distinct !DILocation(line: 54, column: 21, scope: !48, inlinedAt: !53)
!57 = !DILocation(line: 36, column: 5, scope: !23, inlinedAt: !56)
!58 = !DILocation(line: 37, column: 21, scope: !23, inlinedAt: !56)
!59 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !60, file: !3, line: 59, type: !6)
!60 = distinct !DISubprogram(name: "func_D", scope: !3, file: !3, line: 59, type: !24, scopeLine: 59, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !61)
!61 = !{!59, !62, !63}
!62 = !DILocalVariable(name: "blnd", arg: 2, scope: !60, file: !3, line: 59, type: !6)
!63 = !DILocalVariable(name: "blinded_r", scope: !60, file: !3, line: 61, type: !6)
!64 = !DILocation(line: 0, scope: !60, inlinedAt: !65)
!65 = distinct !DILocation(line: 47, column: 23, scope: !39)
!66 = !DILocation(line: 60, column: 5, scope: !60, inlinedAt: !65)
!67 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !68, file: !3, line: 66, type: !6)
!68 = distinct !DISubprogram(name: "func_E", scope: !3, file: !3, line: 66, type: !24, scopeLine: 66, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !69)
!69 = !{!67, !70, !71}
!70 = !DILocalVariable(name: "blnd", arg: 2, scope: !68, file: !3, line: 66, type: !6)
!71 = !DILocalVariable(name: "blinded_r", scope: !68, file: !3, line: 68, type: !6)
!72 = !DILocation(line: 0, scope: !68, inlinedAt: !73)
!73 = distinct !DILocation(line: 61, column: 21, scope: !60, inlinedAt: !65)
!74 = !DILocation(line: 67, column: 5, scope: !68, inlinedAt: !73)
!75 = !DILocation(line: 68, column: 21, scope: !68, inlinedAt: !73)
!76 = !DILocation(line: 48, column: 12, scope: !39)
!77 = !DILocation(line: 48, column: 5, scope: !39)
!78 = !DILocation(line: 0, scope: !48)
!79 = !DILocation(line: 53, column: 5, scope: !48)
!80 = !DILocation(line: 0, scope: !23, inlinedAt: !81)
!81 = distinct !DILocation(line: 54, column: 21, scope: !48)
!82 = !DILocation(line: 36, column: 5, scope: !23, inlinedAt: !81)
!83 = !DILocation(line: 37, column: 21, scope: !23, inlinedAt: !81)
!84 = !DILocation(line: 55, column: 12, scope: !48)
!85 = !DILocation(line: 55, column: 5, scope: !48)
!86 = !DILocation(line: 0, scope: !60)
!87 = !DILocation(line: 60, column: 5, scope: !60)
!88 = !DILocation(line: 0, scope: !68, inlinedAt: !89)
!89 = distinct !DILocation(line: 61, column: 21, scope: !60)
!90 = !DILocation(line: 67, column: 5, scope: !68, inlinedAt: !89)
!91 = !DILocation(line: 68, column: 21, scope: !68, inlinedAt: !89)
!92 = !DILocation(line: 62, column: 12, scope: !60)
!93 = !DILocation(line: 62, column: 5, scope: !60)
!94 = !DILocation(line: 0, scope: !68)
!95 = !DILocation(line: 67, column: 5, scope: !68)
!96 = !DILocation(line: 68, column: 21, scope: !68)
!97 = !DILocation(line: 69, column: 12, scope: !68)
!98 = !DILocation(line: 69, column: 5, scope: !68)
!99 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 78, type: !100, scopeLine: 78, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!100 = !DISubroutineType(types: !101)
!101 = !{!6}
!102 = !DILocation(line: 0, scope: !23, inlinedAt: !103)
!103 = distinct !DILocation(line: 79, column: 5, scope: !99)
!104 = !DILocation(line: 36, column: 5, scope: !23, inlinedAt: !103)
!105 = !DILocation(line: 37, column: 21, scope: !23, inlinedAt: !103)
!106 = !DILocation(line: 0, scope: !11, inlinedAt: !107)
!107 = distinct !DILocation(line: 80, column: 5, scope: !99)
!108 = !DILocation(line: 28, column: 9, scope: !20, inlinedAt: !107)
!109 = !DILocation(line: 81, column: 5, scope: !99)
