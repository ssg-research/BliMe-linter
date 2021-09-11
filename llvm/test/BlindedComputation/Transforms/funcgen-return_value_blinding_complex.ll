; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; XFAIL: *
; //
; FIXME: Enable and update once BlindedDataUsage does proper reporting
; //
; Make sure we correctly handle cases where a loop is such that it is
; fine on first execution, but will violate the taint-spolicy on
; subsequent iterations.
; 
; int arr[100];
; 
; int accessArray(int idx) {
; 	return arr[idx];
; }
; 
; int transform(int idx, int scale, int offset) {
; 	return scale * idx + offset;
; }
; 
; CHECK: Invalid use of blinded data  as operand of BranchInst
; int useKey(__attribute__((blinded)) int idx) {
; 	int sum = 0;
; 	int i = 0;
; 	while (1) {
;     // i is non-blinded on first iteration
; 		sum += accessArray(i);
; 		if (i != 0) break;
; 
;     // But this will taint i for subsequent iterations and
;     // cause the previous if statement to violate the policy!
; 		i = transform(idx, 1, 0);
; 	}
; 
; 	return sum;
; }
; 
; int main() {
; 	return useKey(5);
; }



; ModuleID = 'BlindedComputation/Transforms/funcgen-return_value_blinding_complex.c'
source_filename = "BlindedComputation/Transforms/funcgen-return_value_blinding_complex.c"
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

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @accessArray(i32 %idx) local_unnamed_addr #0 !dbg !14 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !18, metadata !DIExpression()), !dbg !19
  %idxprom = sext i32 %idx to i64, !dbg !20
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom, !dbg !20
  %0 = load i32, i32* %arrayidx, align 4, !dbg !20, !tbaa !21
  ret i32 %0, !dbg !25
}

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i32 @transform(i32 %idx, i32 %scale, i32 %offset) local_unnamed_addr #1 !dbg !26 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !30, metadata !DIExpression()), !dbg !33
  call void @llvm.dbg.value(metadata i32 %scale, metadata !31, metadata !DIExpression()), !dbg !33
  call void @llvm.dbg.value(metadata i32 %offset, metadata !32, metadata !DIExpression()), !dbg !33
  %mul = mul nsw i32 %scale, %idx, !dbg !34
  %add = add nsw i32 %mul, %offset, !dbg !35
  ret i32 %add, !dbg !36
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @useKey(i32 blinded %idx) local_unnamed_addr #0 !dbg !37 {
entry:
  call void @llvm.dbg.value(metadata i32 %idx, metadata !39, metadata !DIExpression()), !dbg !42
  call void @llvm.dbg.value(metadata i32 0, metadata !40, metadata !DIExpression()), !dbg !42
  call void @llvm.dbg.value(metadata i32 0, metadata !41, metadata !DIExpression()), !dbg !42
  br label %while.body, !dbg !43

while.body:                                       ; preds = %while.body, %entry
  %sum.0 = phi i32 [ 0, %entry ], [ %add, %while.body ], !dbg !42
  %i.0 = phi i32 [ 0, %entry ], [ %idx, %while.body ], !dbg !42
  call void @llvm.dbg.value(metadata i32 %i.0, metadata !41, metadata !DIExpression()), !dbg !42
  call void @llvm.dbg.value(metadata i32 %sum.0, metadata !40, metadata !DIExpression()), !dbg !42
  call void @llvm.dbg.value(metadata i32 %i.0, metadata !18, metadata !DIExpression()), !dbg !44
  %idxprom.i = sext i32 %i.0 to i64, !dbg !47
  %arrayidx.i = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom.i, !dbg !47
  %0 = load i32, i32* %arrayidx.i, align 4, !dbg !47, !tbaa !21
  %add = add nsw i32 %0, %sum.0, !dbg !48
  call void @llvm.dbg.value(metadata i32 %add, metadata !40, metadata !DIExpression()), !dbg !42
  %cmp.not = icmp eq i32 %i.0, 0, !dbg !49
  br i1 %cmp.not, label %while.body, label %while.end, !dbg !51, !llvm.loop !52

while.end:                                        ; preds = %while.body
  ret i32 %add, !dbg !55
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @main() local_unnamed_addr #0 !dbg !56 {
entry:
  call void @llvm.dbg.value(metadata i32 5, metadata !39, metadata !DIExpression()), !dbg !59
  call void @llvm.dbg.value(metadata i32 0, metadata !40, metadata !DIExpression()), !dbg !59
  call void @llvm.dbg.value(metadata i32 0, metadata !41, metadata !DIExpression()), !dbg !59
  br label %while.body.i, !dbg !61

while.body.i:                                     ; preds = %while.body.i, %entry
  %sum.0.i = phi i32 [ 0, %entry ], [ %add.i, %while.body.i ], !dbg !59
  %cmp.not.i = phi i1 [ true, %entry ], [ false, %while.body.i ], !dbg !59
  %i.0.i = phi i64 [ 0, %entry ], [ 5, %while.body.i ]
  call void @llvm.dbg.value(metadata i32 undef, metadata !41, metadata !DIExpression()), !dbg !59
  call void @llvm.dbg.value(metadata i32 %sum.0.i, metadata !40, metadata !DIExpression()), !dbg !59
  call void @llvm.dbg.value(metadata i32 undef, metadata !18, metadata !DIExpression()), !dbg !62
  %arrayidx.i.i = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %i.0.i, !dbg !64
  %0 = load i32, i32* %arrayidx.i.i, align 4, !dbg !64, !tbaa !21
  %add.i = add nsw i32 %0, %sum.0.i, !dbg !65
  call void @llvm.dbg.value(metadata i32 %add.i, metadata !40, metadata !DIExpression()), !dbg !59
  br i1 %cmp.not.i, label %while.body.i, label %useKey.exit, !dbg !66, !llvm.loop !67

useKey.exit:                                      ; preds = %while.body.i
  ret i32 %add.i, !dbg !69
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #2

attributes #0 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!10, !11, !12}
!llvm.ident = !{!13}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 10, type: !6, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/funcgen-return_value_blinding_complex.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
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
!16 = !{!7, !7}
!17 = !{!18}
!18 = !DILocalVariable(name: "idx", arg: 1, scope: !14, file: !3, line: 12, type: !7)
!19 = !DILocation(line: 0, scope: !14)
!20 = !DILocation(line: 13, column: 9, scope: !14)
!21 = !{!22, !22, i64 0}
!22 = !{!"int", !23, i64 0}
!23 = !{!"omnipotent char", !24, i64 0}
!24 = !{!"Simple C/C++ TBAA"}
!25 = !DILocation(line: 13, column: 2, scope: !14)
!26 = distinct !DISubprogram(name: "transform", scope: !3, file: !3, line: 16, type: !27, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !29)
!27 = !DISubroutineType(types: !28)
!28 = !{!7, !7, !7, !7}
!29 = !{!30, !31, !32}
!30 = !DILocalVariable(name: "idx", arg: 1, scope: !26, file: !3, line: 16, type: !7)
!31 = !DILocalVariable(name: "scale", arg: 2, scope: !26, file: !3, line: 16, type: !7)
!32 = !DILocalVariable(name: "offset", arg: 3, scope: !26, file: !3, line: 16, type: !7)
!33 = !DILocation(line: 0, scope: !26)
!34 = !DILocation(line: 17, column: 15, scope: !26)
!35 = !DILocation(line: 17, column: 21, scope: !26)
!36 = !DILocation(line: 17, column: 2, scope: !26)
!37 = distinct !DISubprogram(name: "useKey", scope: !3, file: !3, line: 21, type: !15, scopeLine: 21, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !38)
!38 = !{!39, !40, !41}
!39 = !DILocalVariable(name: "idx", arg: 1, scope: !37, file: !3, line: 21, type: !7)
!40 = !DILocalVariable(name: "sum", scope: !37, file: !3, line: 22, type: !7)
!41 = !DILocalVariable(name: "i", scope: !37, file: !3, line: 23, type: !7)
!42 = !DILocation(line: 0, scope: !37)
!43 = !DILocation(line: 24, column: 2, scope: !37)
!44 = !DILocation(line: 0, scope: !14, inlinedAt: !45)
!45 = distinct !DILocation(line: 26, column: 10, scope: !46)
!46 = distinct !DILexicalBlock(scope: !37, file: !3, line: 24, column: 12)
!47 = !DILocation(line: 13, column: 9, scope: !14, inlinedAt: !45)
!48 = !DILocation(line: 26, column: 7, scope: !46)
!49 = !DILocation(line: 27, column: 9, scope: !50)
!50 = distinct !DILexicalBlock(scope: !46, file: !3, line: 27, column: 7)
!51 = !DILocation(line: 27, column: 7, scope: !46)
!52 = distinct !{!52, !43, !53, !54}
!53 = !DILocation(line: 32, column: 2, scope: !37)
!54 = !{!"llvm.loop.unroll.disable"}
!55 = !DILocation(line: 34, column: 2, scope: !37)
!56 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 37, type: !57, scopeLine: 37, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!57 = !DISubroutineType(types: !58)
!58 = !{!7}
!59 = !DILocation(line: 0, scope: !37, inlinedAt: !60)
!60 = distinct !DILocation(line: 38, column: 9, scope: !56)
!61 = !DILocation(line: 24, column: 2, scope: !37, inlinedAt: !60)
!62 = !DILocation(line: 0, scope: !14, inlinedAt: !63)
!63 = distinct !DILocation(line: 26, column: 10, scope: !46, inlinedAt: !60)
!64 = !DILocation(line: 13, column: 9, scope: !14, inlinedAt: !63)
!65 = !DILocation(line: 26, column: 7, scope: !46, inlinedAt: !60)
!66 = !DILocation(line: 27, column: 7, scope: !46, inlinedAt: !60)
!67 = distinct !{!67, !61, !68, !54}
!68 = !DILocation(line: 32, column: 2, scope: !37, inlinedAt: !60)
!69 = !DILocation(line: 38, column: 2, scope: !56)
