; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -I/usr/include/x86_64-linux-gnu -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; 
; #define noinline __attribute__((noinline))
; #define blinded __attribute__((blinded))
; 
; int arr[100];
; int g_var = 1;
; 
; Just eats up a blinded value without further analysis
; void intoTheVoid(blinded int i);
; 
; noinline void sink(int i) {
;   intoTheVoid(i);
; };
; 
; Should get a blinded variant that simply resets blindedness
; noinline int zero(int idx) {
;   sink(idx); // This prevents the compiler from optimizing out calls to this.
; 	return (0 * idx) + g_var; // Add global so compiler cannot ignore return
; }
; 
; noinline
; int transform(int idx, int scale, int offset) {
;   sink(idx); // This prevents the compiler from optimizing out calls to this.
; 	return scale * idx + offset; // Should get tainted if any of the args are.
; }
; 
; We should se one unblinded and one blinded sink call here
; CHECK-LABEL: @test
; CHECK: call {{.*}} @transform.{{[a-z0-9]+}}(
; CHECK: call {{.*}} @zero.{{[a-z0-9]+}}(
; CHECK: call {{.*}} @sink(
; CHECK: call {{.*}} @transform.{{[a-z0-9]+}}(
; CHECK: call {{.*}} @sink.{{[a-z0-9]+}}(
; CHECK: ret i32 57687
; int test(blinded int idx) {
;   // We expect the zero function to not return a blind value!
;   sink(zero(transform(idx, 2, 1)));
;   // But plain old transform with blinded inputs should!
;   sink(transform(idx, 2, 1));
;   return 57687;
; }



; ModuleID = 'BlindedComputation/Transforms/funcgen-return_value_blinding.c'
source_filename = "BlindedComputation/Transforms/funcgen-return_value_blinding.c"
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

@g_var = dso_local local_unnamed_addr global i32 1, align 4, !dbg !0
@arr = dso_local local_unnamed_addr global [100 x i32] zeroinitializer, align 16, !dbg !6

; Function Attrs: noinline nounwind uwtable
define dso_local void @sink(i32 %i) local_unnamed_addr #0 !dbg !16 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !20, metadata !DIExpression()), !dbg !21
  tail call void @intoTheVoid(i32 %i) #4, !dbg !22
  ret void, !dbg !23
}

declare !dbg !24 dso_local void @intoTheVoid(i32) local_unnamed_addr #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @zero(i32 %idx) local_unnamed_addr #0 !dbg !25 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !29, metadata !DIExpression()), !dbg !30
  tail call void @sink(i32 %idx), !dbg !31
  %0 = load i32, i32* @g_var, align 4, !dbg !32, !tbaa !33
  ret i32 %0, !dbg !37
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @transform(i32 %idx, i32 %scale, i32 %offset) local_unnamed_addr #0 !dbg !38 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !42, metadata !DIExpression()), !dbg !45
  call void @llvm.dbg.value(metadata i32 %scale, metadata !43, metadata !DIExpression()), !dbg !45
  call void @llvm.dbg.value(metadata i32 %offset, metadata !44, metadata !DIExpression()), !dbg !45
  tail call void @sink(i32 %idx), !dbg !46
  %mul = mul nsw i32 %scale, %idx, !dbg !47
  %add = add nsw i32 %mul, %offset, !dbg !48
  ret i32 %add, !dbg !49
}

; Function Attrs: nounwind uwtable
define dso_local i32 @test(i32 blinded %idx) local_unnamed_addr #2 !dbg !50 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !52, metadata !DIExpression()), !dbg !53
  %call = tail call i32 @transform(i32 %idx, i32 2, i32 1), !dbg !54
  %call1 = tail call i32 @zero(i32 %call), !dbg !55
  tail call void @sink(i32 %call1), !dbg !56
  %call2 = tail call i32 @transform(i32 %idx, i32 2, i32 1), !dbg !57
  tail call void @sink(i32 %call2), !dbg !58
  ret i32 57687, !dbg !59
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { noinline nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }
attributes #4 = { nounwind }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!12, !13, !14}
!llvm.ident = !{!15}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "g_var", scope: !2, file: !3, line: 7, type: !9, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/funcgen-return_value_blinding.c", directory: "")
!4 = !{}
!5 = !{!0, !6}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 6, type: !8, isLocal: false, isDefinition: true)
!8 = !DICompositeType(tag: DW_TAG_array_type, baseType: !9, size: 3200, elements: !10)
!9 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!10 = !{!11}
!11 = !DISubrange(count: 100)
!12 = !{i32 7, !"Dwarf Version", i32 4}
!13 = !{i32 2, !"Debug Info Version", i32 3}
!14 = !{i32 1, !"wchar_size", i32 4}
!15 = !{!"clang version 11.0.0"}
!16 = distinct !DISubprogram(name: "sink", scope: !3, file: !3, line: 12, type: !17, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !19)
!17 = !DISubroutineType(types: !18)
!18 = !{null, !9}
!19 = !{!20}
!20 = !DILocalVariable(name: "i", arg: 1, scope: !16, file: !3, line: 12, type: !9)
!21 = !DILocation(line: 0, scope: !16)
!22 = !DILocation(line: 13, column: 3, scope: !16)
!23 = !DILocation(line: 14, column: 1, scope: !16)
!24 = !DISubprogram(name: "intoTheVoid", scope: !3, file: !3, line: 10, type: !17, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !4)
!25 = distinct !DISubprogram(name: "zero", scope: !3, file: !3, line: 17, type: !26, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !28)
!26 = !DISubroutineType(types: !27)
!27 = !{!9, !9}
!28 = !{!29}
!29 = !DILocalVariable(name: "idx", arg: 1, scope: !25, file: !3, line: 17, type: !9)
!30 = !DILocation(line: 0, scope: !25)
!31 = !DILocation(line: 18, column: 3, scope: !25)
!32 = !DILocation(line: 19, column: 21, scope: !25)
!33 = !{!34, !34, i64 0}
!34 = !{!"int", !35, i64 0}
!35 = !{!"omnipotent char", !36, i64 0}
!36 = !{!"Simple C/C++ TBAA"}
!37 = !DILocation(line: 19, column: 2, scope: !25)
!38 = distinct !DISubprogram(name: "transform", scope: !3, file: !3, line: 23, type: !39, scopeLine: 23, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !41)
!39 = !DISubroutineType(types: !40)
!40 = !{!9, !9, !9, !9}
!41 = !{!42, !43, !44}
!42 = !DILocalVariable(name: "idx", arg: 1, scope: !38, file: !3, line: 23, type: !9)
!43 = !DILocalVariable(name: "scale", arg: 2, scope: !38, file: !3, line: 23, type: !9)
!44 = !DILocalVariable(name: "offset", arg: 3, scope: !38, file: !3, line: 23, type: !9)
!45 = !DILocation(line: 0, scope: !38)
!46 = !DILocation(line: 24, column: 3, scope: !38)
!47 = !DILocation(line: 25, column: 15, scope: !38)
!48 = !DILocation(line: 25, column: 21, scope: !38)
!49 = !DILocation(line: 25, column: 2, scope: !38)
!50 = distinct !DISubprogram(name: "test", scope: !3, file: !3, line: 36, type: !26, scopeLine: 36, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !51)
!51 = !{!52}
!52 = !DILocalVariable(name: "idx", arg: 1, scope: !50, file: !3, line: 36, type: !9)
!53 = !DILocation(line: 0, scope: !50)
!54 = !DILocation(line: 38, column: 13, scope: !50)
!55 = !DILocation(line: 38, column: 8, scope: !50)
!56 = !DILocation(line: 38, column: 3, scope: !50)
!57 = !DILocation(line: 40, column: 8, scope: !50)
!58 = !DILocation(line: 40, column: 3, scope: !50)
!59 = !DILocation(line: 41, column: 3, scope: !50)
