; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; //
; Make sure having cycles in the call graph doesn't confuse the function
; argument permutation transformations. The function calls in main()
; should trigger multiplication of the other functions, the _no_cylcle
; variants are identical with the exception of the transfrom() function.
; 
; Expect to get new variants for the following functions:
; CHECK-DAG: define dso_local i32 @accessArray.{{[a-z0-9]+}}(
; CHECK-DAG: define dso_local i32 @accessArray_no_cycle.{{[a-z0-9]+}}(
; CHECK-DAG: define dso_local i32 @transform.{{[a-z0-9]+}}(
; CHECK-DAG: define dso_local i32 @transform_no_cycle.{{[a-z0-9]+}}(
; CHECK-DAG: define dso_local i32 @useKey.{{[a-z0-9]+}}(
; CHECK-DAG: define dso_local i32 @useKey_no_cycle.{{[a-z0-9]+}}(
; 
; #define noinline __attribute__((noinline))
; 
; int useKey(int idx, int idx2, int noTransform);
; int useKey_no_cycle(int idx, int idx2, int noTransform);
; 
; int arr[100];
; 
; noinline
; int accessArray(int idx) {
; 	return arr[idx];
; }
; 
; noinline
; int transform(int idx, int scale, int offset) {
; 	return scale * useKey(idx, offset, 1); // will cause cycle
; }
; 
; noinline
; int useKey(int idx, int idx2, int noTransform) {
; 	if (noTransform) return idx + idx2;
; 
; 	return accessArray(transform(idx + idx2, 2, idx2));
; }
; 
; noinline
; int accessArray_no_cycle(int idx) {
; 	return arr[idx];
; }
; 
; noinline
; int transform_no_cycle(int idx, int scale, int offset) {
; 	return scale * (idx + offset); // no cycle
; }
; 
; noinline
; int useKey_no_cycle(int idx, int idx2, int noTransform) {
; 	if (noTransform) return idx + idx2;
; 
; 	return accessArray_no_cycle(transform_no_cycle(idx + idx2, 2, idx2));
; }
; 
; __attribute__((blinded)) int first = 5;
; __attribute__((blinded)) int second = 3;
; 
; int main() {
;   int a = 0;
;   int b = 0;
;   a = useKey(first, second, 0);
;   b = useKey_no_cycle(first, second, 0);
;   return a + b;
; }



; ModuleID = 'BlindedComputation/Transforms/funcgen-cycle_detection.c'
source_filename = "BlindedComputation/Transforms/funcgen-cycle_detection.c"
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

@arr = dso_local local_unnamed_addr global [100 x i32] zeroinitializer, align 16, !dbg !0
@first = dso_local local_unnamed_addr global i32 5, align 4, !dbg !6 #0
@second = dso_local local_unnamed_addr global i32 3, align 4, !dbg !9 #0

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @accessArray(i32 %idx) local_unnamed_addr #1 !dbg !18 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !22, metadata !DIExpression()), !dbg !23
  %idxprom = sext i32 %idx to i64, !dbg !24
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom, !dbg !24
  %0 = load i32, i32* %arrayidx, align 4, !dbg !24, !tbaa !25
  ret i32 %0, !dbg !29
}

; Function Attrs: noinline nounwind readonly uwtable
define dso_local i32 @transform(i32 %idx, i32 %scale, i32 %offset) local_unnamed_addr #2 !dbg !30 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !34, metadata !DIExpression()), !dbg !37
  call void @llvm.dbg.value(metadata i32 %scale, metadata !35, metadata !DIExpression()), !dbg !37
  call void @llvm.dbg.value(metadata i32 %offset, metadata !36, metadata !DIExpression()), !dbg !37
  %call = tail call i32 @useKey(i32 %idx, i32 %offset, i32 1), !dbg !38
  %mul = mul nsw i32 %call, %scale, !dbg !39
  ret i32 %mul, !dbg !40
}

; Function Attrs: noinline nounwind readonly uwtable
define dso_local i32 @useKey(i32 %idx, i32 %idx2, i32 %noTransform) local_unnamed_addr #2 !dbg !41 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !43, metadata !DIExpression()), !dbg !46
  call void @llvm.dbg.value(metadata i32 %idx2, metadata !44, metadata !DIExpression()), !dbg !46
  call void @llvm.dbg.value(metadata i32 %noTransform, metadata !45, metadata !DIExpression()), !dbg !46
  %tobool.not = icmp eq i32 %noTransform, 0, !dbg !47
  %add = add nsw i32 %idx2, %idx, !dbg !46
  br i1 %tobool.not, label %if.end, label %return, !dbg !49

if.end:                                           ; preds = %entry
  %call = tail call i32 @transform(i32 %add, i32 2, i32 %idx2), !dbg !50
  %call2 = tail call i32 @accessArray(i32 %call), !dbg !51
  br label %return, !dbg !52

return:                                           ; preds = %entry, %if.end
  %retval.0 = phi i32 [ %call2, %if.end ], [ %add, %entry ], !dbg !46
  ret i32 %retval.0, !dbg !53
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @accessArray_no_cycle(i32 %idx) local_unnamed_addr #1 !dbg !54 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !56, metadata !DIExpression()), !dbg !57
  %idxprom = sext i32 %idx to i64, !dbg !58
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom, !dbg !58
  %0 = load i32, i32* %arrayidx, align 4, !dbg !58, !tbaa !25
  ret i32 %0, !dbg !59
}

; Function Attrs: noinline norecurse nounwind readnone uwtable
define dso_local i32 @transform_no_cycle(i32 %idx, i32 %scale, i32 %offset) local_unnamed_addr #3 !dbg !60 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !62, metadata !DIExpression()), !dbg !65
  call void @llvm.dbg.value(metadata i32 %scale, metadata !63, metadata !DIExpression()), !dbg !65
  call void @llvm.dbg.value(metadata i32 %offset, metadata !64, metadata !DIExpression()), !dbg !65
  %add = add nsw i32 %offset, %idx, !dbg !66
  %mul = mul nsw i32 %add, %scale, !dbg !67
  ret i32 %mul, !dbg !68
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @useKey_no_cycle(i32 %idx, i32 %idx2, i32 %noTransform) local_unnamed_addr #1 !dbg !69 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !71, metadata !DIExpression()), !dbg !74
  call void @llvm.dbg.value(metadata i32 %idx2, metadata !72, metadata !DIExpression()), !dbg !74
  call void @llvm.dbg.value(metadata i32 %noTransform, metadata !73, metadata !DIExpression()), !dbg !74
  %tobool.not = icmp eq i32 %noTransform, 0, !dbg !75
  %add = add nsw i32 %idx2, %idx, !dbg !74
  br i1 %tobool.not, label %if.end, label %return, !dbg !77

if.end:                                           ; preds = %entry
  %call = tail call i32 @transform_no_cycle(i32 %add, i32 2, i32 %idx2), !dbg !78
  %call2 = tail call i32 @accessArray_no_cycle(i32 %call), !dbg !79
  br label %return, !dbg !80

return:                                           ; preds = %entry, %if.end
  %retval.0 = phi i32 [ %call2, %if.end ], [ %add, %entry ], !dbg !74
  ret i32 %retval.0, !dbg !81
}

; Function Attrs: nounwind readonly uwtable
define dso_local i32 @main() local_unnamed_addr #4 !dbg !82 {
entry:
  call void @llvm.dbg.value(metadata i32 0, metadata !86, metadata !DIExpression()), !dbg !88
  call void @llvm.dbg.value(metadata i32 0, metadata !87, metadata !DIExpression()), !dbg !88
  %0 = load i32, i32* @first, align 4, !dbg !89, !tbaa !25
  %1 = load i32, i32* @second, align 4, !dbg !90, !tbaa !25
  %call = tail call i32 @useKey(i32 %0, i32 %1, i32 0), !dbg !91
  call void @llvm.dbg.value(metadata i32 %call, metadata !86, metadata !DIExpression()), !dbg !88
  %call1 = tail call i32 @useKey_no_cycle(i32 %0, i32 %1, i32 0), !dbg !92
  call void @llvm.dbg.value(metadata i32 %call1, metadata !87, metadata !DIExpression()), !dbg !88
  %add = add nsw i32 %call1, %call, !dbg !93
  ret i32 %add, !dbg !94
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #5

attributes #0 = { blinded }
attributes #1 = { noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { noinline nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { noinline norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!14, !15, !16}
!llvm.ident = !{!17}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 21, type: !11, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/funcgen-cycle_detection.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!4 = !{}
!5 = !{!6, !9, !0}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "first", scope: !2, file: !3, line: 57, type: !8, isLocal: false, isDefinition: true)
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(name: "second", scope: !2, file: !3, line: 58, type: !8, isLocal: false, isDefinition: true)
!11 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 3200, elements: !12)
!12 = !{!13}
!13 = !DISubrange(count: 100)
!14 = !{i32 7, !"Dwarf Version", i32 4}
!15 = !{i32 2, !"Debug Info Version", i32 3}
!16 = !{i32 1, !"wchar_size", i32 4}
!17 = !{!"clang version 11.0.0"}
!18 = distinct !DISubprogram(name: "accessArray", scope: !3, file: !3, line: 24, type: !19, scopeLine: 24, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !21)
!19 = !DISubroutineType(types: !20)
!20 = !{!8, !8}
!21 = !{!22}
!22 = !DILocalVariable(name: "idx", arg: 1, scope: !18, file: !3, line: 24, type: !8)
!23 = !DILocation(line: 0, scope: !18)
!24 = !DILocation(line: 25, column: 9, scope: !18)
!25 = !{!26, !26, i64 0}
!26 = !{!"int", !27, i64 0}
!27 = !{!"omnipotent char", !28, i64 0}
!28 = !{!"Simple C/C++ TBAA"}
!29 = !DILocation(line: 25, column: 2, scope: !18)
!30 = distinct !DISubprogram(name: "transform", scope: !3, file: !3, line: 29, type: !31, scopeLine: 29, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !33)
!31 = !DISubroutineType(types: !32)
!32 = !{!8, !8, !8, !8}
!33 = !{!34, !35, !36}
!34 = !DILocalVariable(name: "idx", arg: 1, scope: !30, file: !3, line: 29, type: !8)
!35 = !DILocalVariable(name: "scale", arg: 2, scope: !30, file: !3, line: 29, type: !8)
!36 = !DILocalVariable(name: "offset", arg: 3, scope: !30, file: !3, line: 29, type: !8)
!37 = !DILocation(line: 0, scope: !30)
!38 = !DILocation(line: 30, column: 17, scope: !30)
!39 = !DILocation(line: 30, column: 15, scope: !30)
!40 = !DILocation(line: 30, column: 2, scope: !30)
!41 = distinct !DISubprogram(name: "useKey", scope: !3, file: !3, line: 34, type: !31, scopeLine: 34, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !42)
!42 = !{!43, !44, !45}
!43 = !DILocalVariable(name: "idx", arg: 1, scope: !41, file: !3, line: 34, type: !8)
!44 = !DILocalVariable(name: "idx2", arg: 2, scope: !41, file: !3, line: 34, type: !8)
!45 = !DILocalVariable(name: "noTransform", arg: 3, scope: !41, file: !3, line: 34, type: !8)
!46 = !DILocation(line: 0, scope: !41)
!47 = !DILocation(line: 35, column: 6, scope: !48)
!48 = distinct !DILexicalBlock(scope: !41, file: !3, line: 35, column: 6)
!49 = !DILocation(line: 35, column: 6, scope: !41)
!50 = !DILocation(line: 37, column: 21, scope: !41)
!51 = !DILocation(line: 37, column: 9, scope: !41)
!52 = !DILocation(line: 37, column: 2, scope: !41)
!53 = !DILocation(line: 38, column: 1, scope: !41)
!54 = distinct !DISubprogram(name: "accessArray_no_cycle", scope: !3, file: !3, line: 41, type: !19, scopeLine: 41, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !55)
!55 = !{!56}
!56 = !DILocalVariable(name: "idx", arg: 1, scope: !54, file: !3, line: 41, type: !8)
!57 = !DILocation(line: 0, scope: !54)
!58 = !DILocation(line: 42, column: 9, scope: !54)
!59 = !DILocation(line: 42, column: 2, scope: !54)
!60 = distinct !DISubprogram(name: "transform_no_cycle", scope: !3, file: !3, line: 46, type: !31, scopeLine: 46, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !61)
!61 = !{!62, !63, !64}
!62 = !DILocalVariable(name: "idx", arg: 1, scope: !60, file: !3, line: 46, type: !8)
!63 = !DILocalVariable(name: "scale", arg: 2, scope: !60, file: !3, line: 46, type: !8)
!64 = !DILocalVariable(name: "offset", arg: 3, scope: !60, file: !3, line: 46, type: !8)
!65 = !DILocation(line: 0, scope: !60)
!66 = !DILocation(line: 47, column: 22, scope: !60)
!67 = !DILocation(line: 47, column: 15, scope: !60)
!68 = !DILocation(line: 47, column: 2, scope: !60)
!69 = distinct !DISubprogram(name: "useKey_no_cycle", scope: !3, file: !3, line: 51, type: !31, scopeLine: 51, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !70)
!70 = !{!71, !72, !73}
!71 = !DILocalVariable(name: "idx", arg: 1, scope: !69, file: !3, line: 51, type: !8)
!72 = !DILocalVariable(name: "idx2", arg: 2, scope: !69, file: !3, line: 51, type: !8)
!73 = !DILocalVariable(name: "noTransform", arg: 3, scope: !69, file: !3, line: 51, type: !8)
!74 = !DILocation(line: 0, scope: !69)
!75 = !DILocation(line: 52, column: 6, scope: !76)
!76 = distinct !DILexicalBlock(scope: !69, file: !3, line: 52, column: 6)
!77 = !DILocation(line: 52, column: 6, scope: !69)
!78 = !DILocation(line: 54, column: 30, scope: !69)
!79 = !DILocation(line: 54, column: 9, scope: !69)
!80 = !DILocation(line: 54, column: 2, scope: !69)
!81 = !DILocation(line: 55, column: 1, scope: !69)
!82 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 60, type: !83, scopeLine: 60, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !85)
!83 = !DISubroutineType(types: !84)
!84 = !{!8}
!85 = !{!86, !87}
!86 = !DILocalVariable(name: "a", scope: !82, file: !3, line: 61, type: !8)
!87 = !DILocalVariable(name: "b", scope: !82, file: !3, line: 62, type: !8)
!88 = !DILocation(line: 0, scope: !82)
!89 = !DILocation(line: 63, column: 14, scope: !82)
!90 = !DILocation(line: 63, column: 21, scope: !82)
!91 = !DILocation(line: 63, column: 7, scope: !82)
!92 = !DILocation(line: 64, column: 7, scope: !82)
!93 = !DILocation(line: 65, column: 12, scope: !82)
!94 = !DILocation(line: 65, column: 3, scope: !82)
