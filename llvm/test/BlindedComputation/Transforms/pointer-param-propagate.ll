; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -I/usr/include/x86_64-linux-gnu -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; XFAIL: *
; 
; #include <stdio.h>
; 
; #define noinline __attribute__((noinline))
; #define blinded __attribute__((blinded))
; 
; blinded int globalBlinded = 12;
; 
; noinline int blnd_a(int a, int* b) {
; 	*b = a;
; 	return a;
; }
; 
; noinline void blnd_b(blinded int* q) {
;   *q = 15;
; }
; 
; noinline int use_blnd_a(blinded int blnd_arg) {
; 	int non_blnd = 7;
; 
;   // will propagate blnd_arg to the non_blnd pointer
; 	blnd_a(blnd_arg, &non_blnd);
; 
;   // the braching based on the value of non_blnd will be tainted
;   return non_blnd;
; }
; 
; noinline int use_blnd_b(int* normal_arg) {
;   blnd_b(normal_arg);
;   if (*normal_arg > 0) {
;     return 12;
;   }
;   else {
;     return 10;
;   }
; }
; 
; int main() {
;     int non_blnd_b = 10, non_blnd_c;
;     // a: the parameter is not blinded. But tainted inside.
;     // b: the parameter is blinded, though the input pointer is overwritten
;     //    by a non-sensitive value.
;     int used_a = use_blnd_a(15);
;     int used_b = use_blnd_b(&non_blnd_b);
;     printf("%d, %d", used_a, used_b);
; 
;     return 0;
; }



; ModuleID = 'BlindedComputation/Transforms/pointer-param-propagate.c'
source_filename = "BlindedComputation/Transforms/pointer-param-propagate.c"
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

@globalBlinded = dso_local local_unnamed_addr global i32 12, align 4, !dbg !0 #0
@.str = private unnamed_addr constant [7 x i8] c"%d, %d\00", align 1

; Function Attrs: nofree noinline norecurse nounwind uwtable writeonly
define dso_local i32 @blnd_a(i32 returned %a, i32* nocapture %b) local_unnamed_addr #1 !dbg !11 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !16, metadata !DIExpression()), !dbg !18
  call void @llvm.dbg.value(metadata i32* %b, metadata !17, metadata !DIExpression()), !dbg !18
  store i32 %a, i32* %b, align 4, !dbg !19, !tbaa !20
  ret i32 %a, !dbg !24
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #2

; Function Attrs: nofree noinline norecurse nounwind uwtable writeonly
define dso_local void @blnd_b(i32* blinded nocapture %q) local_unnamed_addr #1 !dbg !25 {
entry:
  call void @llvm.dbg.value(metadata i32* %q, metadata !29, metadata !DIExpression()), !dbg !30
  store i32 15, i32* %q, align 4, !dbg !31, !tbaa !20
  ret void, !dbg !32
}

; Function Attrs: nofree noinline norecurse nounwind uwtable writeonly
define dso_local i32 @use_blnd_a(i32 blinded %blnd_arg) local_unnamed_addr #1 !dbg !33 {
entry:
  %non_blnd = alloca i32, align 4
  call void @llvm.dbg.value(metadata i32 %blnd_arg, metadata !37, metadata !DIExpression()), !dbg !39
  call void @llvm.dbg.value(metadata i32 7, metadata !38, metadata !DIExpression()), !dbg !39
  store i32 7, i32* %non_blnd, align 4, !dbg !40, !tbaa !20
  call void @llvm.dbg.value(metadata i32* %non_blnd, metadata !38, metadata !DIExpression(DW_OP_deref)), !dbg !39
  %call = call i32 @blnd_a(i32 %blnd_arg, i32* nonnull %non_blnd), !dbg !41
  %0 = load i32, i32* %non_blnd, align 4, !dbg !42, !tbaa !20
  call void @llvm.dbg.value(metadata i32 %0, metadata !38, metadata !DIExpression()), !dbg !39
  ret i32 %0, !dbg !43
}

; Function Attrs: nofree noinline norecurse nounwind uwtable
define dso_local i32 @use_blnd_b(i32* nocapture %normal_arg) local_unnamed_addr #3 !dbg !44 {
entry:
  call void @llvm.dbg.value(metadata i32* %normal_arg, metadata !48, metadata !DIExpression()), !dbg !49
  tail call void @blnd_b(i32* %normal_arg), !dbg !50
  %0 = load i32, i32* %normal_arg, align 4, !dbg !51, !tbaa !20
  %cmp = icmp sgt i32 %0, 0, !dbg !53
  %. = select i1 %cmp, i32 12, i32 10, !dbg !54
  ret i32 %., !dbg !55
}

; Function Attrs: nofree nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #4 !dbg !56 {
entry:
  %non_blnd_b = alloca i32, align 4
  call void @llvm.dbg.value(metadata i32 10, metadata !60, metadata !DIExpression()), !dbg !64
  store i32 10, i32* %non_blnd_b, align 4, !dbg !65, !tbaa !20
  call void @llvm.dbg.declare(metadata i32* undef, metadata !61, metadata !DIExpression()), !dbg !66
  %call = tail call i32 @use_blnd_a(i32 15), !dbg !67
  call void @llvm.dbg.value(metadata i32 %call, metadata !62, metadata !DIExpression()), !dbg !64
  call void @llvm.dbg.value(metadata i32* %non_blnd_b, metadata !60, metadata !DIExpression(DW_OP_deref)), !dbg !64
  %call1 = call i32 @use_blnd_b(i32* nonnull %non_blnd_b), !dbg !68
  call void @llvm.dbg.value(metadata i32 %call1, metadata !63, metadata !DIExpression()), !dbg !64
  %call2 = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i64 0, i64 0), i32 %call, i32 %call1), !dbg !69
  ret i32 0, !dbg !70
}

; Function Attrs: nofree nounwind
declare dso_local i32 @printf(i8* nocapture readonly, ...) local_unnamed_addr #5

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #2

attributes #0 = { blinded }
attributes #1 = { nofree noinline norecurse nounwind uwtable writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone speculatable willreturn }
attributes #3 = { nofree noinline norecurse nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nofree nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nofree nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!7, !8, !9}
!llvm.ident = !{!10}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "globalBlinded", scope: !2, file: !3, line: 9, type: !6, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/pointer-param-propagate.c", directory: "")
!4 = !{}
!5 = !{!0}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = !{i32 7, !"Dwarf Version", i32 4}
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 1, !"wchar_size", i32 4}
!10 = !{!"clang version 11.0.0"}
!11 = distinct !DISubprogram(name: "blnd_a", scope: !3, file: !3, line: 11, type: !12, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !15)
!12 = !DISubroutineType(types: !13)
!13 = !{!6, !6, !14}
!14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !6, size: 64)
!15 = !{!16, !17}
!16 = !DILocalVariable(name: "a", arg: 1, scope: !11, file: !3, line: 11, type: !6)
!17 = !DILocalVariable(name: "b", arg: 2, scope: !11, file: !3, line: 11, type: !14)
!18 = !DILocation(line: 0, scope: !11)
!19 = !DILocation(line: 12, column: 5, scope: !11)
!20 = !{!21, !21, i64 0}
!21 = !{!"int", !22, i64 0}
!22 = !{!"omnipotent char", !23, i64 0}
!23 = !{!"Simple C/C++ TBAA"}
!24 = !DILocation(line: 13, column: 2, scope: !11)
!25 = distinct !DISubprogram(name: "blnd_b", scope: !3, file: !3, line: 16, type: !26, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !28)
!26 = !DISubroutineType(types: !27)
!27 = !{null, !14}
!28 = !{!29}
!29 = !DILocalVariable(name: "q", arg: 1, scope: !25, file: !3, line: 16, type: !14)
!30 = !DILocation(line: 0, scope: !25)
!31 = !DILocation(line: 17, column: 6, scope: !25)
!32 = !DILocation(line: 18, column: 1, scope: !25)
!33 = distinct !DISubprogram(name: "use_blnd_a", scope: !3, file: !3, line: 20, type: !34, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !36)
!34 = !DISubroutineType(types: !35)
!35 = !{!6, !6}
!36 = !{!37, !38}
!37 = !DILocalVariable(name: "blnd_arg", arg: 1, scope: !33, file: !3, line: 20, type: !6)
!38 = !DILocalVariable(name: "non_blnd", scope: !33, file: !3, line: 21, type: !6)
!39 = !DILocation(line: 0, scope: !33)
!40 = !DILocation(line: 21, column: 6, scope: !33)
!41 = !DILocation(line: 24, column: 2, scope: !33)
!42 = !DILocation(line: 27, column: 10, scope: !33)
!43 = !DILocation(line: 27, column: 3, scope: !33)
!44 = distinct !DISubprogram(name: "use_blnd_b", scope: !3, file: !3, line: 30, type: !45, scopeLine: 30, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !47)
!45 = !DISubroutineType(types: !46)
!46 = !{!6, !14}
!47 = !{!48}
!48 = !DILocalVariable(name: "normal_arg", arg: 1, scope: !44, file: !3, line: 30, type: !14)
!49 = !DILocation(line: 0, scope: !44)
!50 = !DILocation(line: 31, column: 3, scope: !44)
!51 = !DILocation(line: 32, column: 7, scope: !52)
!52 = distinct !DILexicalBlock(scope: !44, file: !3, line: 32, column: 7)
!53 = !DILocation(line: 32, column: 19, scope: !52)
!54 = !DILocation(line: 0, scope: !52)
!55 = !DILocation(line: 38, column: 1, scope: !44)
!56 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 40, type: !57, scopeLine: 40, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !59)
!57 = !DISubroutineType(types: !58)
!58 = !{!6}
!59 = !{!60, !61, !62, !63}
!60 = !DILocalVariable(name: "non_blnd_b", scope: !56, file: !3, line: 41, type: !6)
!61 = !DILocalVariable(name: "non_blnd_c", scope: !56, file: !3, line: 41, type: !6)
!62 = !DILocalVariable(name: "used_a", scope: !56, file: !3, line: 45, type: !6)
!63 = !DILocalVariable(name: "used_b", scope: !56, file: !3, line: 46, type: !6)
!64 = !DILocation(line: 0, scope: !56)
!65 = !DILocation(line: 41, column: 9, scope: !56)
!66 = !DILocation(line: 41, column: 26, scope: !56)
!67 = !DILocation(line: 45, column: 18, scope: !56)
!68 = !DILocation(line: 46, column: 18, scope: !56)
!69 = !DILocation(line: 47, column: 5, scope: !56)
!70 = !DILocation(line: 49, column: 5, scope: !56)
