; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; XFAIL: *
; FIXME: Add proper checks here and remove XFAIL.
; 
; int arr[100];
; 
; int zero(int idx) {
; 	return 0 * idx;
; }
; 
; int accessArray(int idx) {
; 	return arr[idx];
; }
; 
; int transform(int idx, int scale, int offset) {
; 	return scale * idx + offset;
; }
; 
; int useKey2(__attribute__((blinded)) int idx) {
; 	return zero(accessArray(transform(idx, 2, 1))) + accessArray(transform(0, 0, 0));
; }
; 
; int main() {
; 	return useKey2(5);
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

@arr = dso_local local_unnamed_addr global [100 x i32] zeroinitializer, align 16, !dbg !0

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i32 @zero(i32 %idx) local_unnamed_addr #0 !dbg !14 {
entry:
  call void @llvm.dbg.value(metadata i32 undef, metadata !18, metadata !DIExpression()), !dbg !19
  ret i32 0, !dbg !20
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @accessArray(i32 %idx) local_unnamed_addr #1 !dbg !21 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !23, metadata !DIExpression()), !dbg !24
  %idxprom = sext i32 %idx to i64, !dbg !25
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom, !dbg !25
  %0 = load i32, i32* %arrayidx, align 4, !dbg !25, !tbaa !26
  ret i32 %0, !dbg !30
}

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i32 @transform(i32 %idx, i32 %scale, i32 %offset) local_unnamed_addr #0 !dbg !31 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !35, metadata !DIExpression()), !dbg !38
  call void @llvm.dbg.value(metadata i32 %scale, metadata !36, metadata !DIExpression()), !dbg !38
  call void @llvm.dbg.value(metadata i32 %offset, metadata !37, metadata !DIExpression()), !dbg !38
  %mul = mul nsw i32 %scale, %idx, !dbg !39
  %add = add nsw i32 %mul, %offset, !dbg !40
  ret i32 %add, !dbg !41
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @useKey2(i32 blinded %idx) local_unnamed_addr #1 !dbg !42 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !44, metadata !DIExpression()), !dbg !45
  call void @llvm.dbg.value(metadata i32 0, metadata !23, metadata !DIExpression()), !dbg !46
  %0 = load i32, i32* getelementptr inbounds ([100 x i32], [100 x i32]* @arr, i64 0, i64 0), align 16, !dbg !48, !tbaa !26
  ret i32 %0, !dbg !49
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @main() local_unnamed_addr #1 !dbg !50 {
entry:
  call void @llvm.dbg.value(metadata i32 5, metadata !44, metadata !DIExpression()), !dbg !53
  call void @llvm.dbg.value(metadata i32 0, metadata !23, metadata !DIExpression()), !dbg !55
  %0 = load i32, i32* getelementptr inbounds ([100 x i32], [100 x i32]* @arr, i64 0, i64 0), align 16, !dbg !57, !tbaa !26
  ret i32 %0, !dbg !58
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #2

attributes #0 = { norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!10, !11, !12}
!llvm.ident = !{!13}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 5, type: !6, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0.0 (git@gitlab.com:ssg-research/platsec/attack-tolerant-execution/bc-llvm.git 1c77bda76783d7415c21705b687c7297c8a273af)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/funcgen-return_value_blinding.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!4 = !{}
!5 = !{!0}
!6 = !DICompositeType(tag: DW_TAG_array_type, baseType: !7, size: 3200, elements: !8)
!7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!8 = !{!9}
!9 = !DISubrange(count: 100)
!10 = !{i32 7, !"Dwarf Version", i32 4}
!11 = !{i32 2, !"Debug Info Version", i32 3}
!12 = !{i32 1, !"wchar_size", i32 4}
!13 = !{!"clang version 11.0.0"}
!14 = distinct !DISubprogram(name: "zero", scope: !3, file: !3, line: 7, type: !15, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !17)
!15 = !DISubroutineType(types: !16)
!16 = !{!7, !7}
!17 = !{!18}
!18 = !DILocalVariable(name: "idx", arg: 1, scope: !14, file: !3, line: 7, type: !7)
!19 = !DILocation(line: 0, scope: !14)
!20 = !DILocation(line: 8, column: 2, scope: !14)
!21 = distinct !DISubprogram(name: "accessArray", scope: !3, file: !3, line: 11, type: !15, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !22)
!22 = !{!23}
!23 = !DILocalVariable(name: "idx", arg: 1, scope: !21, file: !3, line: 11, type: !7)
!24 = !DILocation(line: 0, scope: !21)
!25 = !DILocation(line: 12, column: 9, scope: !21)
!26 = !{!27, !27, i64 0}
!27 = !{!"int", !28, i64 0}
!28 = !{!"omnipotent char", !29, i64 0}
!29 = !{!"Simple C/C++ TBAA"}
!30 = !DILocation(line: 12, column: 2, scope: !21)
!31 = distinct !DISubprogram(name: "transform", scope: !3, file: !3, line: 15, type: !32, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !34)
!32 = !DISubroutineType(types: !33)
!33 = !{!7, !7, !7, !7}
!34 = !{!35, !36, !37}
!35 = !DILocalVariable(name: "idx", arg: 1, scope: !31, file: !3, line: 15, type: !7)
!36 = !DILocalVariable(name: "scale", arg: 2, scope: !31, file: !3, line: 15, type: !7)
!37 = !DILocalVariable(name: "offset", arg: 3, scope: !31, file: !3, line: 15, type: !7)
!38 = !DILocation(line: 0, scope: !31)
!39 = !DILocation(line: 16, column: 15, scope: !31)
!40 = !DILocation(line: 16, column: 21, scope: !31)
!41 = !DILocation(line: 16, column: 2, scope: !31)
!42 = distinct !DISubprogram(name: "useKey2", scope: !3, file: !3, line: 19, type: !15, scopeLine: 19, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !43)
!43 = !{!44}
!44 = !DILocalVariable(name: "idx", arg: 1, scope: !42, file: !3, line: 19, type: !7)
!45 = !DILocation(line: 0, scope: !42)
!46 = !DILocation(line: 0, scope: !21, inlinedAt: !47)
!47 = distinct !DILocation(line: 20, column: 51, scope: !42)
!48 = !DILocation(line: 12, column: 9, scope: !21, inlinedAt: !47)
!49 = !DILocation(line: 20, column: 2, scope: !42)
!50 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 23, type: !51, scopeLine: 23, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!51 = !DISubroutineType(types: !52)
!52 = !{!7}
!53 = !DILocation(line: 0, scope: !42, inlinedAt: !54)
!54 = distinct !DILocation(line: 24, column: 9, scope: !50)
!55 = !DILocation(line: 0, scope: !21, inlinedAt: !56)
!56 = distinct !DILocation(line: 20, column: 51, scope: !42, inlinedAt: !54)
!57 = !DILocation(line: 12, column: 9, scope: !21, inlinedAt: !56)
!58 = !DILocation(line: 24, column: 2, scope: !50)
