; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; 
; int arr[100];
; 
; We expect to have 6 new variants of this function!
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; __attribute__((noinline))
; int accessArray(int idx, int idx2, int idx3) {
; 	return arr[idx] + arr[idx2] + arr[idx3];
; }
; 
; __attribute__((noinline))
; int useKey(__attribute__((blinded)) int idx) {
; 	return accessArray(idx, 1, 1) + accessArray(1, idx, 1) + accessArray(1, 1, idx) + accessArray(2 * idx, 0, idx + 1) + accessArray(idx, idx, idx)
; 		+ accessArray(2 * idx, 3 * idx, idx + 5);
; }
; 
; int main() {
; 	return useKey(5);
; }



; ModuleID = 'BlindedComputation/Transforms/funcgen-auto_param_blinding.c'
source_filename = "BlindedComputation/Transforms/funcgen-auto_param_blinding.c"
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

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @accessArray(i32 %idx, i32 %idx2, i32 %idx3) local_unnamed_addr #0 !dbg !14 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !18, metadata !DIExpression()), !dbg !21
  call void @llvm.dbg.value(metadata i32 %idx2, metadata !19, metadata !DIExpression()), !dbg !21
  call void @llvm.dbg.value(metadata i32 %idx3, metadata !20, metadata !DIExpression()), !dbg !21
  %idxprom = sext i32 %idx to i64, !dbg !22
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom, !dbg !22
  %0 = load i32, i32* %arrayidx, align 4, !dbg !22, !tbaa !23
  %idxprom1 = sext i32 %idx2 to i64, !dbg !27
  %arrayidx2 = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom1, !dbg !27
  %1 = load i32, i32* %arrayidx2, align 4, !dbg !27, !tbaa !23
  %add = add nsw i32 %1, %0, !dbg !28
  %idxprom3 = sext i32 %idx3 to i64, !dbg !29
  %arrayidx4 = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom3, !dbg !29
  %2 = load i32, i32* %arrayidx4, align 4, !dbg !29, !tbaa !23
  %add5 = add nsw i32 %add, %2, !dbg !30
  ret i32 %add5, !dbg !31
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @useKey(i32 blinded %idx) local_unnamed_addr #0 !dbg !32 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !36, metadata !DIExpression()), !dbg !37
  %call = tail call i32 @accessArray(i32 %idx, i32 1, i32 1), !dbg !38
  %call1 = tail call i32 @accessArray(i32 1, i32 %idx, i32 1), !dbg !39
  %add = add nsw i32 %call1, %call, !dbg !40
  %call2 = tail call i32 @accessArray(i32 1, i32 1, i32 %idx), !dbg !41
  %add3 = add nsw i32 %add, %call2, !dbg !42
  %mul = shl nsw i32 %idx, 1, !dbg !43
  %add4 = add nsw i32 %idx, 1, !dbg !44
  %call5 = tail call i32 @accessArray(i32 %mul, i32 0, i32 %add4), !dbg !45
  %add6 = add nsw i32 %add3, %call5, !dbg !46
  %call7 = tail call i32 @accessArray(i32 %idx, i32 %idx, i32 %idx), !dbg !47
  %add8 = add nsw i32 %add6, %call7, !dbg !48
  %mul10 = mul nsw i32 %idx, 3, !dbg !49
  %add11 = add nsw i32 %idx, 5, !dbg !50
  %call12 = tail call i32 @accessArray(i32 %mul, i32 %mul10, i32 %add11), !dbg !51
  %add13 = add nsw i32 %add8, %call12, !dbg !52
  ret i32 %add13, !dbg !53
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @main() local_unnamed_addr #1 !dbg !54 {
entry:
  %call = tail call i32 @useKey(i32 5), !dbg !57
  ret i32 %call, !dbg !58
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #2

attributes #0 = { noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!10, !11, !12}
!llvm.ident = !{!13}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 3, type: !6, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/funcgen-auto_param_blinding.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
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
!14 = distinct !DISubprogram(name: "accessArray", scope: !3, file: !3, line: 12, type: !15, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !17)
!15 = !DISubroutineType(types: !16)
!16 = !{!7, !7, !7, !7}
!17 = !{!18, !19, !20}
!18 = !DILocalVariable(name: "idx", arg: 1, scope: !14, file: !3, line: 12, type: !7)
!19 = !DILocalVariable(name: "idx2", arg: 2, scope: !14, file: !3, line: 12, type: !7)
!20 = !DILocalVariable(name: "idx3", arg: 3, scope: !14, file: !3, line: 12, type: !7)
!21 = !DILocation(line: 0, scope: !14)
!22 = !DILocation(line: 13, column: 9, scope: !14)
!23 = !{!24, !24, i64 0}
!24 = !{!"int", !25, i64 0}
!25 = !{!"omnipotent char", !26, i64 0}
!26 = !{!"Simple C/C++ TBAA"}
!27 = !DILocation(line: 13, column: 20, scope: !14)
!28 = !DILocation(line: 13, column: 18, scope: !14)
!29 = !DILocation(line: 13, column: 32, scope: !14)
!30 = !DILocation(line: 13, column: 30, scope: !14)
!31 = !DILocation(line: 13, column: 2, scope: !14)
!32 = distinct !DISubprogram(name: "useKey", scope: !3, file: !3, line: 17, type: !33, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !35)
!33 = !DISubroutineType(types: !34)
!34 = !{!7, !7}
!35 = !{!36}
!36 = !DILocalVariable(name: "idx", arg: 1, scope: !32, file: !3, line: 17, type: !7)
!37 = !DILocation(line: 0, scope: !32)
!38 = !DILocation(line: 18, column: 9, scope: !32)
!39 = !DILocation(line: 18, column: 34, scope: !32)
!40 = !DILocation(line: 18, column: 32, scope: !32)
!41 = !DILocation(line: 18, column: 59, scope: !32)
!42 = !DILocation(line: 18, column: 57, scope: !32)
!43 = !DILocation(line: 18, column: 98, scope: !32)
!44 = !DILocation(line: 18, column: 112, scope: !32)
!45 = !DILocation(line: 18, column: 84, scope: !32)
!46 = !DILocation(line: 18, column: 82, scope: !32)
!47 = !DILocation(line: 18, column: 119, scope: !32)
!48 = !DILocation(line: 18, column: 117, scope: !32)
!49 = !DILocation(line: 19, column: 28, scope: !32)
!50 = !DILocation(line: 19, column: 39, scope: !32)
!51 = !DILocation(line: 19, column: 5, scope: !32)
!52 = !DILocation(line: 19, column: 3, scope: !32)
!53 = !DILocation(line: 18, column: 2, scope: !32)
!54 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 22, type: !55, scopeLine: 22, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!55 = !DISubroutineType(types: !56)
!56 = !{!7}
!57 = !DILocation(line: 23, column: 9, scope: !54)
!58 = !DILocation(line: 23, column: 2, scope: !54)
