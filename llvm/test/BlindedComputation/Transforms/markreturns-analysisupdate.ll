; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -I/usr/include/x86_64-linux-gnu -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; //
; Test whether we are dependent on tranformation order. Specifically, the 
; gimme_blind_* function here are used in simpleTest but are partially
; define both before or after the definition of simpleTest.
; 
; We would expect that both calls to need_blind_var are converted to the
; blinded variant (which does get properly created due to the sanityCheck).
; However, because the calls are nested, the blindedness must propagate
; through the function calls in the gimme_blind chain, which in turn causes
; an error if the transfromation are order dependent and do not properly
; invalidate prior resutls or reprocess functions.
; #define noinline __attribute__((noinline))
; #define blinded __attribute__((blinded))
; 
; blinded int g_arr[10];
; blinded int g_blinded = 0;
; 
; noinline int gimme_blind_a1(int i);
; noinline int gimme_blind_a2(int i);
; noinline int gimme_blind_a3(int i);
; noinline int gimme_blind_a4(int i);
; noinline int gimme_blind_b1(int i);
; noinline int gimme_blind_b2(int i);
; noinline int gimme_blind_b3(int i);
; noinline int gimme_blind_b4(int i);
; 
; int gimme_blind_a1(int i) { return gimme_blind_a2(i); }
; int gimme_blind_a2(int i) { return gimme_blind_a3(i); }
; int gimme_blind_a3(int i) { return gimme_blind_a4(i); }
; int gimme_blind_a4(int i) { return g_blinded + i; }
; 
; CHECK-LABEL: @need_blind_var
; noinline int need_blind_var(int i) {
;   return g_arr[i];
; }
; 
; Expect both calls to need_blind_var to have been converted!
; //
; CHECK-LABEL: @simpleTest
; CHECK-DAG: call i32 @need_blind_var.1
; CHECK-DAG: call i32 @need_blind_var.1
; CHECK-DAG: call i32 @gimme_blind_a1
; CHECK-DAG: call i32 @gimme_blind_b1
; CHECK: ret i32
; int simpleTest(blinded int a) {
;   return need_blind_var(gimme_blind_a1(1)) + need_blind_var(gimme_blind_b1(2));
; }
; 
; int gimme_blind_b1(int i) { return gimme_blind_b2(i); }
; int gimme_blind_b2(int i) { return gimme_blind_b3(i); }
; int gimme_blind_b3(int i) { return gimme_blind_b4(i); }
; int gimme_blind_b4(int i) { return g_blinded + i; }
; 
; This function should alway trigger the creation of a new blinded
; variant of need_blinded_var!
; //
; CHECK-LABEL: define {{.*}} @sanityCheck
; CHECK-LABEL: define {{.*}} @need_blind_var{{\.[a-z0-9]+}}(
; int sanityCheck() {
;   return need_blind_var(g_blinded);
; }



; ModuleID = 'BlindedComputation/Transforms/markreturns-analysisupdate.c'
source_filename = "BlindedComputation/Transforms/markreturns-analysisupdate.c"
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
define dso_local i32 @gimme_blind_a1(i32 %i) local_unnamed_addr #1 !dbg !16 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !20, metadata !DIExpression()), !dbg !21
  %call = tail call i32 @gimme_blind_a2(i32 %i), !dbg !22
  ret i32 %call, !dbg !23
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_a2(i32 %i) local_unnamed_addr #1 !dbg !24 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !26, metadata !DIExpression()), !dbg !27
  %call = tail call i32 @gimme_blind_a3(i32 %i), !dbg !28
  ret i32 %call, !dbg !29
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_a3(i32 %i) local_unnamed_addr #1 !dbg !30 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !32, metadata !DIExpression()), !dbg !33
  %call = tail call i32 @gimme_blind_a4(i32 %i), !dbg !34
  ret i32 %call, !dbg !35
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_a4(i32 %i) local_unnamed_addr #1 !dbg !36 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !38, metadata !DIExpression()), !dbg !39
  %0 = load i32, i32* @g_blinded, align 4, !dbg !40, !tbaa !41
  %add = add nsw i32 %0, %i, !dbg !45
  ret i32 %add, !dbg !46
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @need_blind_var(i32 %i) local_unnamed_addr #1 !dbg !47 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !49, metadata !DIExpression()), !dbg !50
  %idxprom = sext i32 %i to i64, !dbg !51
  %arrayidx = getelementptr inbounds [10 x i32], [10 x i32]* @g_arr, i64 0, i64 %idxprom, !dbg !51
  %0 = load i32, i32* %arrayidx, align 4, !dbg !51, !tbaa !41
  ret i32 %0, !dbg !52
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @simpleTest(i32 blinded %a) local_unnamed_addr #2 !dbg !53 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !55, metadata !DIExpression()), !dbg !56
  %call = tail call i32 @gimme_blind_a1(i32 1), !dbg !57
  %call1 = tail call i32 @need_blind_var(i32 %call), !dbg !58
  %call2 = tail call i32 @gimme_blind_b1(i32 2), !dbg !59
  %call3 = tail call i32 @need_blind_var(i32 %call2), !dbg !60
  %add = add nsw i32 %call3, %call1, !dbg !61
  ret i32 %add, !dbg !62
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_b1(i32 %i) local_unnamed_addr #1 !dbg !63 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !65, metadata !DIExpression()), !dbg !66
  %call = tail call i32 @gimme_blind_b2(i32 %i), !dbg !67
  ret i32 %call, !dbg !68
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_b2(i32 %i) local_unnamed_addr #1 !dbg !69 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !71, metadata !DIExpression()), !dbg !72
  %call = tail call i32 @gimme_blind_b3(i32 %i), !dbg !73
  ret i32 %call, !dbg !74
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_b3(i32 %i) local_unnamed_addr #1 !dbg !75 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !77, metadata !DIExpression()), !dbg !78
  %call = tail call i32 @gimme_blind_b4(i32 %i), !dbg !79
  ret i32 %call, !dbg !80
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_b4(i32 %i) local_unnamed_addr #1 !dbg !81 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !83, metadata !DIExpression()), !dbg !84
  %0 = load i32, i32* @g_blinded, align 4, !dbg !85, !tbaa !41
  %add = add nsw i32 %0, %i, !dbg !86
  ret i32 %add, !dbg !87
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @sanityCheck() local_unnamed_addr #2 !dbg !88 {
entry:
  %0 = load i32, i32* @g_blinded, align 4, !dbg !91, !tbaa !41
  %call = tail call i32 @need_blind_var(i32 %0), !dbg !92
  ret i32 %call, !dbg !93
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { blinded }
attributes #1 = { noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!12, !13, !14}
!llvm.ident = !{!15}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "g_blinded", scope: !2, file: !3, line: 17, type: !9, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/markreturns-analysisupdate.c", directory: "")
!4 = !{}
!5 = !{!0, !6}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "g_arr", scope: !2, file: !3, line: 16, type: !8, isLocal: false, isDefinition: true)
!8 = !DICompositeType(tag: DW_TAG_array_type, baseType: !9, size: 320, elements: !10)
!9 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!10 = !{!11}
!11 = !DISubrange(count: 10)
!12 = !{i32 7, !"Dwarf Version", i32 4}
!13 = !{i32 2, !"Debug Info Version", i32 3}
!14 = !{i32 1, !"wchar_size", i32 4}
!15 = !{!"clang version 11.0.0"}
!16 = distinct !DISubprogram(name: "gimme_blind_a1", scope: !3, file: !3, line: 28, type: !17, scopeLine: 28, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !19)
!17 = !DISubroutineType(types: !18)
!18 = !{!9, !9}
!19 = !{!20}
!20 = !DILocalVariable(name: "i", arg: 1, scope: !16, file: !3, line: 28, type: !9)
!21 = !DILocation(line: 0, scope: !16)
!22 = !DILocation(line: 28, column: 36, scope: !16)
!23 = !DILocation(line: 28, column: 29, scope: !16)
!24 = distinct !DISubprogram(name: "gimme_blind_a2", scope: !3, file: !3, line: 29, type: !17, scopeLine: 29, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !25)
!25 = !{!26}
!26 = !DILocalVariable(name: "i", arg: 1, scope: !24, file: !3, line: 29, type: !9)
!27 = !DILocation(line: 0, scope: !24)
!28 = !DILocation(line: 29, column: 36, scope: !24)
!29 = !DILocation(line: 29, column: 29, scope: !24)
!30 = distinct !DISubprogram(name: "gimme_blind_a3", scope: !3, file: !3, line: 30, type: !17, scopeLine: 30, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !31)
!31 = !{!32}
!32 = !DILocalVariable(name: "i", arg: 1, scope: !30, file: !3, line: 30, type: !9)
!33 = !DILocation(line: 0, scope: !30)
!34 = !DILocation(line: 30, column: 36, scope: !30)
!35 = !DILocation(line: 30, column: 29, scope: !30)
!36 = distinct !DISubprogram(name: "gimme_blind_a4", scope: !3, file: !3, line: 31, type: !17, scopeLine: 31, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !37)
!37 = !{!38}
!38 = !DILocalVariable(name: "i", arg: 1, scope: !36, file: !3, line: 31, type: !9)
!39 = !DILocation(line: 0, scope: !36)
!40 = !DILocation(line: 31, column: 36, scope: !36)
!41 = !{!42, !42, i64 0}
!42 = !{!"int", !43, i64 0}
!43 = !{!"omnipotent char", !44, i64 0}
!44 = !{!"Simple C/C++ TBAA"}
!45 = !DILocation(line: 31, column: 46, scope: !36)
!46 = !DILocation(line: 31, column: 29, scope: !36)
!47 = distinct !DISubprogram(name: "need_blind_var", scope: !3, file: !3, line: 34, type: !17, scopeLine: 34, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !48)
!48 = !{!49}
!49 = !DILocalVariable(name: "i", arg: 1, scope: !47, file: !3, line: 34, type: !9)
!50 = !DILocation(line: 0, scope: !47)
!51 = !DILocation(line: 35, column: 10, scope: !47)
!52 = !DILocation(line: 35, column: 3, scope: !47)
!53 = distinct !DISubprogram(name: "simpleTest", scope: !3, file: !3, line: 46, type: !17, scopeLine: 46, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !54)
!54 = !{!55}
!55 = !DILocalVariable(name: "a", arg: 1, scope: !53, file: !3, line: 46, type: !9)
!56 = !DILocation(line: 0, scope: !53)
!57 = !DILocation(line: 47, column: 25, scope: !53)
!58 = !DILocation(line: 47, column: 10, scope: !53)
!59 = !DILocation(line: 47, column: 61, scope: !53)
!60 = !DILocation(line: 47, column: 46, scope: !53)
!61 = !DILocation(line: 47, column: 44, scope: !53)
!62 = !DILocation(line: 47, column: 3, scope: !53)
!63 = distinct !DISubprogram(name: "gimme_blind_b1", scope: !3, file: !3, line: 50, type: !17, scopeLine: 50, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !64)
!64 = !{!65}
!65 = !DILocalVariable(name: "i", arg: 1, scope: !63, file: !3, line: 50, type: !9)
!66 = !DILocation(line: 0, scope: !63)
!67 = !DILocation(line: 50, column: 36, scope: !63)
!68 = !DILocation(line: 50, column: 29, scope: !63)
!69 = distinct !DISubprogram(name: "gimme_blind_b2", scope: !3, file: !3, line: 51, type: !17, scopeLine: 51, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !70)
!70 = !{!71}
!71 = !DILocalVariable(name: "i", arg: 1, scope: !69, file: !3, line: 51, type: !9)
!72 = !DILocation(line: 0, scope: !69)
!73 = !DILocation(line: 51, column: 36, scope: !69)
!74 = !DILocation(line: 51, column: 29, scope: !69)
!75 = distinct !DISubprogram(name: "gimme_blind_b3", scope: !3, file: !3, line: 52, type: !17, scopeLine: 52, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !76)
!76 = !{!77}
!77 = !DILocalVariable(name: "i", arg: 1, scope: !75, file: !3, line: 52, type: !9)
!78 = !DILocation(line: 0, scope: !75)
!79 = !DILocation(line: 52, column: 36, scope: !75)
!80 = !DILocation(line: 52, column: 29, scope: !75)
!81 = distinct !DISubprogram(name: "gimme_blind_b4", scope: !3, file: !3, line: 53, type: !17, scopeLine: 53, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !82)
!82 = !{!83}
!83 = !DILocalVariable(name: "i", arg: 1, scope: !81, file: !3, line: 53, type: !9)
!84 = !DILocation(line: 0, scope: !81)
!85 = !DILocation(line: 53, column: 36, scope: !81)
!86 = !DILocation(line: 53, column: 46, scope: !81)
!87 = !DILocation(line: 53, column: 29, scope: !81)
!88 = distinct !DISubprogram(name: "sanityCheck", scope: !3, file: !3, line: 60, type: !89, scopeLine: 60, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!89 = !DISubroutineType(types: !90)
!90 = !{!9}
!91 = !DILocation(line: 61, column: 25, scope: !88)
!92 = !DILocation(line: 61, column: 10, scope: !88)
!93 = !DILocation(line: 61, column: 3, scope: !88)
