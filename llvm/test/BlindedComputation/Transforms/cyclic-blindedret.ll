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
; int sink;
; blinded int global_ret_blnd;
; int func_A(int non_blnd, blinded int blnd);
; int func_B(int non_blnd, blinded int blnd);
; int func_C(int non_blnd, blinded int blnd);
; int func_D(int non_blnd, blinded int blnd);
; int func_E(int non_blnd, blinded int blnd);
; 
; CHECK-DAG: call i32 @func_SELF({{.*}}), {{.*}} !my.md.blinded
; noinline int func_SELF(unsigned int non_blnd, blinded int blnd) {
;     if (non_blnd == 0) {
;         printf("%d", non_blnd);
;         return blnd;
;     }
;     sink += non_blnd;
;     func_SELF(non_blnd + sink, blnd);
;     printf("%d", non_blnd);
; }
; 
; CHECK-DAG: call i32 @func_B(i32 1, i32 2), {{.*}} !my.md.blinded
; noinline int func_A(blinded int blnd, int non_blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_B(1, 2);
;     return global_ret_blnd;
; }
; 
; 
; CHECK-DAG: call i32 @func_C(i32 3, i32 4), {{.*}} !my.md.blinded
; CHECK-DAG: call i32 @func_D(i32 7, i32 8), {{.*}} !my.md.blinded
; noinline int func_B(int non_blnd, blinded int blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_C(3, 4);
;     int blinded_r_2 = func_D(7, 8);
;     return global_ret_blnd;
; }
; 
; CHECK-DAG: call i32 @func_A(i32 5, i32 6), {{.*}} !my.md.blinded
; noinline int func_C(int non_blnd, blinded int blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_A(5, 6);
;     return global_ret_blnd;
; }
; 
; CHECK-DAG: call i32 @func_E(i32 9, i32 10), {{.*}} !my.md.blinded
; noinline int func_D(int non_blnd, blinded int blnd) {
;     printf("%d %d", blnd, non_blnd);
;     int blinded_r = func_E(9, 10);
;     return global_ret_blnd;
; }
; 
; CHECK-DAG: call i32 @func_B(i32 11, i32 12), {{.*}} !my.md.blinded
; noinline int func_E(int non_blnd, blinded int blnd) {
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
@sink = dso_local local_unnamed_addr global i32 0, align 4, !dbg !0
@.str.1 = private unnamed_addr constant [6 x i8] c"%d %d\00", align 1
@global_ret_blnd = dso_local local_unnamed_addr global i32 0, align 4, !dbg !6 #0

; Function Attrs: nofree noinline nounwind uwtable
define dso_local i32 @func_SELF(i32 %non_blnd, i32 blinded returned %blnd) local_unnamed_addr #1 !dbg !13 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !18, metadata !DIExpression()), !dbg !20
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !19, metadata !DIExpression()), !dbg !20
  %cmp = icmp eq i32 %non_blnd, 0, !dbg !21
  br i1 %cmp, label %if.then, label %if.end, !dbg !23

if.then:                                          ; preds = %entry
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([3 x i8], [3 x i8]* @.str, i64 0, i64 0), i32 0), !dbg !24
  ret i32 %blnd, !dbg !26

if.end:                                           ; preds = %entry
  %0 = load i32, i32* @sink, align 4, !dbg !27, !tbaa !28
  %add = add i32 %0, %non_blnd, !dbg !27
  store i32 %add, i32* @sink, align 4, !dbg !27, !tbaa !28
  %add1 = add i32 %add, %non_blnd, !dbg !32
  %call2 = tail call i32 @func_SELF(i32 %add1, i32 %blnd), !dbg !33
  %call3 = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([3 x i8], [3 x i8]* @.str, i64 0, i64 0), i32 %non_blnd), !dbg !34
  ret i32 %blnd, !dbg !26
}

; Function Attrs: nofree nounwind
declare dso_local i32 @printf(i8* nocapture readonly, ...) local_unnamed_addr #2

; Function Attrs: nofree noinline nounwind uwtable
define dso_local i32 @func_A(i32 blinded %blnd, i32 %non_blnd) local_unnamed_addr #1 !dbg !35 {
entry:
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !39, metadata !DIExpression()), !dbg !42
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !40, metadata !DIExpression()), !dbg !42
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !43
  %call1 = tail call i32 @func_B(i32 1, i32 2), !dbg !44
  call void @llvm.dbg.value(metadata i32 %call1, metadata !41, metadata !DIExpression()), !dbg !42
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !45, !tbaa !28
  ret i32 %0, !dbg !46
}

; Function Attrs: nofree noinline nounwind uwtable
define dso_local i32 @func_B(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !47 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !49, metadata !DIExpression()), !dbg !53
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !50, metadata !DIExpression()), !dbg !53
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !54
  %call1 = tail call i32 @func_C(i32 3, i32 4), !dbg !55
  call void @llvm.dbg.value(metadata i32 %call1, metadata !51, metadata !DIExpression()), !dbg !53
  %call2 = tail call i32 @func_D(i32 7, i32 8), !dbg !56
  call void @llvm.dbg.value(metadata i32 %call2, metadata !52, metadata !DIExpression()), !dbg !53
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !57, !tbaa !28
  ret i32 %0, !dbg !58
}

; Function Attrs: nofree noinline nounwind uwtable
define dso_local i32 @func_C(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !59 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !61, metadata !DIExpression()), !dbg !64
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !62, metadata !DIExpression()), !dbg !64
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !65
  %call1 = tail call i32 @func_A(i32 5, i32 6), !dbg !66
  call void @llvm.dbg.value(metadata i32 %call1, metadata !63, metadata !DIExpression()), !dbg !64
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !67, !tbaa !28
  ret i32 %0, !dbg !68
}

; Function Attrs: nofree noinline nounwind uwtable
define dso_local i32 @func_D(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !69 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !71, metadata !DIExpression()), !dbg !74
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !72, metadata !DIExpression()), !dbg !74
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !75
  %call1 = tail call i32 @func_E(i32 9, i32 10), !dbg !76
  call void @llvm.dbg.value(metadata i32 %call1, metadata !73, metadata !DIExpression()), !dbg !74
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !77, !tbaa !28
  ret i32 %0, !dbg !78
}

; Function Attrs: nofree noinline nounwind uwtable
define dso_local i32 @func_E(i32 %non_blnd, i32 blinded %blnd) local_unnamed_addr #1 !dbg !79 {
entry:
  call void @llvm.dbg.value(metadata i32 %non_blnd, metadata !81, metadata !DIExpression()), !dbg !84
  call void @llvm.dbg.value(metadata i32 %blnd, metadata !82, metadata !DIExpression()), !dbg !84
  %call = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i32 %blnd, i32 %non_blnd), !dbg !85
  %call1 = tail call i32 @func_B(i32 11, i32 12), !dbg !86
  call void @llvm.dbg.value(metadata i32 %call1, metadata !83, metadata !DIExpression()), !dbg !84
  %0 = load i32, i32* @global_ret_blnd, align 4, !dbg !87, !tbaa !28
  ret i32 %0, !dbg !88
}

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #3 !dbg !89 {
entry:
  %call = tail call i32 @func_A(i32 5, i32 7), !dbg !92
  %call1 = tail call i32 @func_SELF(i32 2, i32 15), !dbg !93
  ret i32 0, !dbg !94
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #4

attributes #0 = { blinded }
attributes #1 = { nofree noinline nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nofree nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!9, !10, !11}
!llvm.ident = !{!12}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "sink", scope: !2, file: !3, line: 18, type: !8, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/cyclic-blindedret.c", directory: "")
!4 = !{}
!5 = !{!0, !6}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "global_ret_blnd", scope: !2, file: !3, line: 19, type: !8, isLocal: false, isDefinition: true)
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!9 = !{i32 7, !"Dwarf Version", i32 4}
!10 = !{i32 2, !"Debug Info Version", i32 3}
!11 = !{i32 1, !"wchar_size", i32 4}
!12 = !{!"clang version 11.0.0"}
!13 = distinct !DISubprogram(name: "func_SELF", scope: !3, file: !3, line: 27, type: !14, scopeLine: 27, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !17)
!14 = !DISubroutineType(types: !15)
!15 = !{!8, !16, !8}
!16 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!17 = !{!18, !19}
!18 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !13, file: !3, line: 27, type: !16)
!19 = !DILocalVariable(name: "blnd", arg: 2, scope: !13, file: !3, line: 27, type: !8)
!20 = !DILocation(line: 0, scope: !13)
!21 = !DILocation(line: 28, column: 18, scope: !22)
!22 = distinct !DILexicalBlock(scope: !13, file: !3, line: 28, column: 9)
!23 = !DILocation(line: 28, column: 9, scope: !13)
!24 = !DILocation(line: 29, column: 9, scope: !25)
!25 = distinct !DILexicalBlock(scope: !22, file: !3, line: 28, column: 24)
!26 = !DILocation(line: 35, column: 1, scope: !13)
!27 = !DILocation(line: 32, column: 10, scope: !13)
!28 = !{!29, !29, i64 0}
!29 = !{!"int", !30, i64 0}
!30 = !{!"omnipotent char", !31, i64 0}
!31 = !{!"Simple C/C++ TBAA"}
!32 = !DILocation(line: 33, column: 24, scope: !13)
!33 = !DILocation(line: 33, column: 5, scope: !13)
!34 = !DILocation(line: 34, column: 5, scope: !13)
!35 = distinct !DISubprogram(name: "func_A", scope: !3, file: !3, line: 38, type: !36, scopeLine: 38, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !38)
!36 = !DISubroutineType(types: !37)
!37 = !{!8, !8, !8}
!38 = !{!39, !40, !41}
!39 = !DILocalVariable(name: "blnd", arg: 1, scope: !35, file: !3, line: 38, type: !8)
!40 = !DILocalVariable(name: "non_blnd", arg: 2, scope: !35, file: !3, line: 38, type: !8)
!41 = !DILocalVariable(name: "blinded_r", scope: !35, file: !3, line: 40, type: !8)
!42 = !DILocation(line: 0, scope: !35)
!43 = !DILocation(line: 39, column: 5, scope: !35)
!44 = !DILocation(line: 40, column: 21, scope: !35)
!45 = !DILocation(line: 41, column: 12, scope: !35)
!46 = !DILocation(line: 41, column: 5, scope: !35)
!47 = distinct !DISubprogram(name: "func_B", scope: !3, file: !3, line: 47, type: !36, scopeLine: 47, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !48)
!48 = !{!49, !50, !51, !52}
!49 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !47, file: !3, line: 47, type: !8)
!50 = !DILocalVariable(name: "blnd", arg: 2, scope: !47, file: !3, line: 47, type: !8)
!51 = !DILocalVariable(name: "blinded_r", scope: !47, file: !3, line: 49, type: !8)
!52 = !DILocalVariable(name: "blinded_r_2", scope: !47, file: !3, line: 50, type: !8)
!53 = !DILocation(line: 0, scope: !47)
!54 = !DILocation(line: 48, column: 5, scope: !47)
!55 = !DILocation(line: 49, column: 21, scope: !47)
!56 = !DILocation(line: 50, column: 23, scope: !47)
!57 = !DILocation(line: 51, column: 12, scope: !47)
!58 = !DILocation(line: 51, column: 5, scope: !47)
!59 = distinct !DISubprogram(name: "func_C", scope: !3, file: !3, line: 55, type: !36, scopeLine: 55, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !60)
!60 = !{!61, !62, !63}
!61 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !59, file: !3, line: 55, type: !8)
!62 = !DILocalVariable(name: "blnd", arg: 2, scope: !59, file: !3, line: 55, type: !8)
!63 = !DILocalVariable(name: "blinded_r", scope: !59, file: !3, line: 57, type: !8)
!64 = !DILocation(line: 0, scope: !59)
!65 = !DILocation(line: 56, column: 5, scope: !59)
!66 = !DILocation(line: 57, column: 21, scope: !59)
!67 = !DILocation(line: 58, column: 12, scope: !59)
!68 = !DILocation(line: 58, column: 5, scope: !59)
!69 = distinct !DISubprogram(name: "func_D", scope: !3, file: !3, line: 62, type: !36, scopeLine: 62, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !70)
!70 = !{!71, !72, !73}
!71 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !69, file: !3, line: 62, type: !8)
!72 = !DILocalVariable(name: "blnd", arg: 2, scope: !69, file: !3, line: 62, type: !8)
!73 = !DILocalVariable(name: "blinded_r", scope: !69, file: !3, line: 64, type: !8)
!74 = !DILocation(line: 0, scope: !69)
!75 = !DILocation(line: 63, column: 5, scope: !69)
!76 = !DILocation(line: 64, column: 21, scope: !69)
!77 = !DILocation(line: 65, column: 12, scope: !69)
!78 = !DILocation(line: 65, column: 5, scope: !69)
!79 = distinct !DISubprogram(name: "func_E", scope: !3, file: !3, line: 69, type: !36, scopeLine: 69, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !80)
!80 = !{!81, !82, !83}
!81 = !DILocalVariable(name: "non_blnd", arg: 1, scope: !79, file: !3, line: 69, type: !8)
!82 = !DILocalVariable(name: "blnd", arg: 2, scope: !79, file: !3, line: 69, type: !8)
!83 = !DILocalVariable(name: "blinded_r", scope: !79, file: !3, line: 71, type: !8)
!84 = !DILocation(line: 0, scope: !79)
!85 = !DILocation(line: 70, column: 5, scope: !79)
!86 = !DILocation(line: 71, column: 21, scope: !79)
!87 = !DILocation(line: 72, column: 12, scope: !79)
!88 = !DILocation(line: 72, column: 5, scope: !79)
!89 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 81, type: !90, scopeLine: 81, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!90 = !DISubroutineType(types: !91)
!91 = !{!8}
!92 = !DILocation(line: 82, column: 5, scope: !89)
!93 = !DILocation(line: 83, column: 5, scope: !89)
!94 = !DILocation(line: 84, column: 5, scope: !89)
