; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; XFAIL: *
; FIXME: Add proper checks here and remove XFAIL.
; 
; int useKey(int idx, int idx2, int noTransform);
; 
; int arr[100];
; 
; int accessArray(int idx) {
; 	return arr[idx];
; }
; 
; int transform(int idx, int scale, int offset) {
; 	return scale * useKey(idx, offset, 1); // will cause cycle
; 	// return scale * (idx + offset); // no cycle
; }
; 
; int useKey(int idx, int idx2, int noTransform) {
; 	if (noTransform) return idx + idx2;
; 
; 	return accessArray(transform(idx + idx2, 2, idx2));
; }
; 
; __attribute__((blinded)) int first = 5;
; __attribute__((blinded)) int second = 3;
; 
; int main() {
; 	return useKey(first, second, 0);
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

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @accessArray(i32 %idx) local_unnamed_addr #1 !dbg !18 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !22, metadata !DIExpression()), !dbg !23
  %idxprom = sext i32 %idx to i64, !dbg !24
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom, !dbg !24
  %0 = load i32, i32* %arrayidx, align 4, !dbg !24, !tbaa !25
  ret i32 %0, !dbg !29
}

; Function Attrs: nounwind readonly uwtable
define dso_local i32 @transform(i32 %idx, i32 %scale, i32 %offset) local_unnamed_addr #2 !dbg !30 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !34, metadata !DIExpression()), !dbg !37
  call void @llvm.dbg.value(metadata i32 %scale, metadata !35, metadata !DIExpression()), !dbg !37
  call void @llvm.dbg.value(metadata i32 %offset, metadata !36, metadata !DIExpression()), !dbg !37
  call void @llvm.dbg.value(metadata i32 %idx, metadata !38, metadata !DIExpression()), !dbg !43
  call void @llvm.dbg.value(metadata i32 %offset, metadata !41, metadata !DIExpression()), !dbg !43
  call void @llvm.dbg.value(metadata i32 1, metadata !42, metadata !DIExpression()), !dbg !43
  %add.i = add nsw i32 %offset, %idx, !dbg !43
  %mul = mul nsw i32 %add.i, %scale, !dbg !45
  ret i32 %mul, !dbg !46
}

; Function Attrs: nounwind readonly uwtable
define dso_local i32 @useKey(i32 %idx, i32 %idx2, i32 %noTransform) local_unnamed_addr #2 !dbg !39 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !38, metadata !DIExpression()), !dbg !47
  call void @llvm.dbg.value(metadata i32 %idx2, metadata !41, metadata !DIExpression()), !dbg !47
  call void @llvm.dbg.value(metadata i32 %noTransform, metadata !42, metadata !DIExpression()), !dbg !47
  %tobool.not = icmp eq i32 %noTransform, 0, !dbg !48
  %add = add nsw i32 %idx2, %idx, !dbg !47
  br i1 %tobool.not, label %if.end, label %return, !dbg !50

if.end:                                           ; preds = %entry
  call void @llvm.dbg.value(metadata i32 %add, metadata !34, metadata !DIExpression()), !dbg !51
  call void @llvm.dbg.value(metadata i32 2, metadata !35, metadata !DIExpression()), !dbg !51
  call void @llvm.dbg.value(metadata i32 %idx2, metadata !36, metadata !DIExpression()), !dbg !51
  call void @llvm.dbg.value(metadata i32 %add, metadata !38, metadata !DIExpression()), !dbg !53
  call void @llvm.dbg.value(metadata i32 %idx2, metadata !41, metadata !DIExpression()), !dbg !53
  call void @llvm.dbg.value(metadata i32 1, metadata !42, metadata !DIExpression()), !dbg !53
  %add.i.i = add nsw i32 %add, %idx2, !dbg !53
  %mul.i = shl nsw i32 %add.i.i, 1, !dbg !55
  call void @llvm.dbg.value(metadata i32 %mul.i, metadata !22, metadata !DIExpression()), !dbg !56
  %idxprom.i = sext i32 %mul.i to i64, !dbg !58
  %arrayidx.i = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom.i, !dbg !58
  %0 = load i32, i32* %arrayidx.i, align 8, !dbg !58, !tbaa !25
  br label %return, !dbg !59

return:                                           ; preds = %entry, %if.end
  %retval.0 = phi i32 [ %0, %if.end ], [ %add, %entry ], !dbg !47
  ret i32 %retval.0, !dbg !60
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @main() local_unnamed_addr #1 !dbg !61 {
entry:
  %0 = load i32, i32* @first, align 4, !dbg !64, !tbaa !25
  %1 = load i32, i32* @second, align 4, !dbg !65, !tbaa !25
  call void @llvm.dbg.value(metadata i32 %0, metadata !38, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata i32 %1, metadata !41, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata i32 0, metadata !42, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata i32 undef, metadata !34, metadata !DIExpression()), !dbg !68
  call void @llvm.dbg.value(metadata i32 2, metadata !35, metadata !DIExpression()), !dbg !68
  call void @llvm.dbg.value(metadata i32 %1, metadata !36, metadata !DIExpression()), !dbg !68
  call void @llvm.dbg.value(metadata i32 undef, metadata !38, metadata !DIExpression()), !dbg !70
  call void @llvm.dbg.value(metadata i32 %1, metadata !41, metadata !DIExpression()), !dbg !70
  call void @llvm.dbg.value(metadata i32 1, metadata !42, metadata !DIExpression()), !dbg !70
  %reass.add = shl i32 %1, 1, !dbg !70
  %add.i.i.i = add i32 %reass.add, %0, !dbg !70
  %mul.i.i = shl nsw i32 %add.i.i.i, 1, !dbg !72
  call void @llvm.dbg.value(metadata i32 %mul.i.i, metadata !22, metadata !DIExpression()), !dbg !73
  %idxprom.i.i = sext i32 %mul.i.i to i64, !dbg !75
  %arrayidx.i.i = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom.i.i, !dbg !75
  %2 = load i32, i32* %arrayidx.i.i, align 8, !dbg !75, !tbaa !25
  ret i32 %2, !dbg !76
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { blinded }
attributes #1 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!14, !15, !16}
!llvm.ident = !{!17}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 7, type: !11, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/funcgen-cycle_detection.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!4 = !{}
!5 = !{!6, !9, !0}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "first", scope: !2, file: !3, line: 24, type: !8, isLocal: false, isDefinition: true)
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(name: "second", scope: !2, file: !3, line: 25, type: !8, isLocal: false, isDefinition: true)
!11 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 3200, elements: !12)
!12 = !{!13}
!13 = !DISubrange(count: 100)
!14 = !{i32 7, !"Dwarf Version", i32 4}
!15 = !{i32 2, !"Debug Info Version", i32 3}
!16 = !{i32 1, !"wchar_size", i32 4}
!17 = !{!"clang version 11.0.0"}
!18 = distinct !DISubprogram(name: "accessArray", scope: !3, file: !3, line: 9, type: !19, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !21)
!19 = !DISubroutineType(types: !20)
!20 = !{!8, !8}
!21 = !{!22}
!22 = !DILocalVariable(name: "idx", arg: 1, scope: !18, file: !3, line: 9, type: !8)
!23 = !DILocation(line: 0, scope: !18)
!24 = !DILocation(line: 10, column: 9, scope: !18)
!25 = !{!26, !26, i64 0}
!26 = !{!"int", !27, i64 0}
!27 = !{!"omnipotent char", !28, i64 0}
!28 = !{!"Simple C/C++ TBAA"}
!29 = !DILocation(line: 10, column: 2, scope: !18)
!30 = distinct !DISubprogram(name: "transform", scope: !3, file: !3, line: 13, type: !31, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !33)
!31 = !DISubroutineType(types: !32)
!32 = !{!8, !8, !8, !8}
!33 = !{!34, !35, !36}
!34 = !DILocalVariable(name: "idx", arg: 1, scope: !30, file: !3, line: 13, type: !8)
!35 = !DILocalVariable(name: "scale", arg: 2, scope: !30, file: !3, line: 13, type: !8)
!36 = !DILocalVariable(name: "offset", arg: 3, scope: !30, file: !3, line: 13, type: !8)
!37 = !DILocation(line: 0, scope: !30)
!38 = !DILocalVariable(name: "idx", arg: 1, scope: !39, file: !3, line: 18, type: !8)
!39 = distinct !DISubprogram(name: "useKey", scope: !3, file: !3, line: 18, type: !31, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !40)
!40 = !{!38, !41, !42}
!41 = !DILocalVariable(name: "idx2", arg: 2, scope: !39, file: !3, line: 18, type: !8)
!42 = !DILocalVariable(name: "noTransform", arg: 3, scope: !39, file: !3, line: 18, type: !8)
!43 = !DILocation(line: 0, scope: !39, inlinedAt: !44)
!44 = distinct !DILocation(line: 14, column: 17, scope: !30)
!45 = !DILocation(line: 14, column: 15, scope: !30)
!46 = !DILocation(line: 14, column: 2, scope: !30)
!47 = !DILocation(line: 0, scope: !39)
!48 = !DILocation(line: 19, column: 6, scope: !49)
!49 = distinct !DILexicalBlock(scope: !39, file: !3, line: 19, column: 6)
!50 = !DILocation(line: 19, column: 6, scope: !39)
!51 = !DILocation(line: 0, scope: !30, inlinedAt: !52)
!52 = distinct !DILocation(line: 21, column: 21, scope: !39)
!53 = !DILocation(line: 0, scope: !39, inlinedAt: !54)
!54 = distinct !DILocation(line: 14, column: 17, scope: !30, inlinedAt: !52)
!55 = !DILocation(line: 14, column: 15, scope: !30, inlinedAt: !52)
!56 = !DILocation(line: 0, scope: !18, inlinedAt: !57)
!57 = distinct !DILocation(line: 21, column: 9, scope: !39)
!58 = !DILocation(line: 10, column: 9, scope: !18, inlinedAt: !57)
!59 = !DILocation(line: 21, column: 2, scope: !39)
!60 = !DILocation(line: 22, column: 1, scope: !39)
!61 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 27, type: !62, scopeLine: 27, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!62 = !DISubroutineType(types: !63)
!63 = !{!8}
!64 = !DILocation(line: 28, column: 16, scope: !61)
!65 = !DILocation(line: 28, column: 23, scope: !61)
!66 = !DILocation(line: 0, scope: !39, inlinedAt: !67)
!67 = distinct !DILocation(line: 28, column: 9, scope: !61)
!68 = !DILocation(line: 0, scope: !30, inlinedAt: !69)
!69 = distinct !DILocation(line: 21, column: 21, scope: !39, inlinedAt: !67)
!70 = !DILocation(line: 0, scope: !39, inlinedAt: !71)
!71 = distinct !DILocation(line: 14, column: 17, scope: !30, inlinedAt: !69)
!72 = !DILocation(line: 14, column: 15, scope: !30, inlinedAt: !69)
!73 = !DILocation(line: 0, scope: !18, inlinedAt: !74)
!74 = distinct !DILocation(line: 21, column: 9, scope: !39, inlinedAt: !67)
!75 = !DILocation(line: 10, column: 9, scope: !18, inlinedAt: !74)
!76 = !DILocation(line: 28, column: 2, scope: !61)
