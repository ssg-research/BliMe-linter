; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -I/usr/include/x86_64-linux-gnu -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; #include <stdint>
; 
; CHECK-LABEL: @arrayMess2
; CHECK-NOT: select
; CHECK: ret i32
; 
; This should 
; int arrayMess2(__attribute__((blinded)) int cond, int mod, int idx1, int idx2) {
;   int a[10] = {1,2,3,4,5,6,7,8,9,0};
;   int b[10] = {0,9,8,7,6,5,4,3,2,1};
; 
;   for (int i = 0; i < 10; ++i) {
;     a[i] += mod;
;     b[i] -= mod;
;   }
; 
;   return cond > 10 ? a[idx1] : b[idx2];
; }



; ModuleID = 'BlindedComputation/Transforms/select-element.c'
source_filename = "BlindedComputation/Transforms/select-element.c"
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

@__const.arrayMess2.a = private unnamed_addr constant [10 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 0], align 16
@__const.arrayMess2.b = private unnamed_addr constant [10 x i32] [i32 0, i32 9, i32 8, i32 7, i32 6, i32 5, i32 4, i32 3, i32 2, i32 1], align 16

; Function Attrs: nounwind readnone uwtable
define dso_local i32 @arrayMess2(i32 blinded %cond, i32 %mod, i32 %idx1, i32 %idx2) local_unnamed_addr #0 !dbg !7 {
entry:
  %a = alloca [10 x i32], align 16
  %b = alloca [10 x i32], align 16
  call void @llvm.dbg.value(metadata i32 %cond, metadata !12, metadata !DIExpression()), !dbg !23
  call void @llvm.dbg.value(metadata i32 %mod, metadata !13, metadata !DIExpression()), !dbg !23
  call void @llvm.dbg.value(metadata i32 %idx1, metadata !14, metadata !DIExpression()), !dbg !23
  call void @llvm.dbg.value(metadata i32 %idx2, metadata !15, metadata !DIExpression()), !dbg !23
  call void @llvm.dbg.declare(metadata [10 x i32]* %a, metadata !16, metadata !DIExpression()), !dbg !24
  %0 = bitcast [10 x i32]* %a to i8*, !dbg !24
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(40) %0, i8* nonnull align 16 dereferenceable(40) bitcast ([10 x i32]* @__const.arrayMess2.a to i8*), i64 40, i1 false), !dbg !24
  call void @llvm.dbg.declare(metadata [10 x i32]* %b, metadata !20, metadata !DIExpression()), !dbg !25
  %1 = bitcast [10 x i32]* %b to i8*, !dbg !25
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(40) %1, i8* nonnull align 16 dereferenceable(40) bitcast ([10 x i32]* @__const.arrayMess2.b to i8*), i64 40, i1 false), !dbg !25
  call void @llvm.dbg.value(metadata i32 0, metadata !21, metadata !DIExpression()), !dbg !26
  br label %for.body, !dbg !27

for.body:                                         ; preds = %for.body, %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  call void @llvm.dbg.value(metadata i64 %indvars.iv, metadata !21, metadata !DIExpression()), !dbg !26
  %arrayidx = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 %indvars.iv, !dbg !28
  %2 = load i32, i32* %arrayidx, align 4, !dbg !31, !tbaa !32
  %add = add nsw i32 %2, %mod, !dbg !31
  store i32 %add, i32* %arrayidx, align 4, !dbg !31, !tbaa !32
  %arrayidx2 = getelementptr inbounds [10 x i32], [10 x i32]* %b, i64 0, i64 %indvars.iv, !dbg !36
  %3 = load i32, i32* %arrayidx2, align 4, !dbg !37, !tbaa !32
  %sub = sub nsw i32 %3, %mod, !dbg !37
  store i32 %sub, i32* %arrayidx2, align 4, !dbg !37, !tbaa !32
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !38
  call void @llvm.dbg.value(metadata i64 %indvars.iv.next, metadata !21, metadata !DIExpression()), !dbg !26
  %exitcond.not = icmp eq i64 %indvars.iv.next, 10, !dbg !39
  br i1 %exitcond.not, label %for.end, label %for.body, !dbg !27, !llvm.loop !40

for.end:                                          ; preds = %for.body
  %cmp3 = icmp sgt i32 %cond, 10, !dbg !43
  %idxprom4 = sext i32 %idx1 to i64, !dbg !44
  %arrayidx5 = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 %idxprom4, !dbg !44
  %idxprom6 = sext i32 %idx2 to i64, !dbg !44
  %arrayidx7 = getelementptr inbounds [10 x i32], [10 x i32]* %b, i64 0, i64 %idxprom6, !dbg !44
  %cond8.in = select i1 %cmp3, i32* %arrayidx5, i32* %arrayidx7, !dbg !44
  %cond8 = load i32, i32* %cond8.in, align 4, !dbg !44, !tbaa !32
  ret i32 %cond8, !dbg !45
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #2

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }
attributes #2 = { argmemonly nounwind willreturn }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4, !5}
!llvm.ident = !{!6}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "BlindedComputation/Transforms/select-element.c", directory: "")
!2 = !{}
!3 = !{i32 7, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = !{i32 1, !"wchar_size", i32 4}
!6 = !{!"clang version 11.0.0"}
!7 = distinct !DISubprogram(name: "arrayMess2", scope: !1, file: !1, line: 9, type: !8, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !11)
!8 = !DISubroutineType(types: !9)
!9 = !{!10, !10, !10, !10, !10}
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !{!12, !13, !14, !15, !16, !20, !21}
!12 = !DILocalVariable(name: "cond", arg: 1, scope: !7, file: !1, line: 9, type: !10)
!13 = !DILocalVariable(name: "mod", arg: 2, scope: !7, file: !1, line: 9, type: !10)
!14 = !DILocalVariable(name: "idx1", arg: 3, scope: !7, file: !1, line: 9, type: !10)
!15 = !DILocalVariable(name: "idx2", arg: 4, scope: !7, file: !1, line: 9, type: !10)
!16 = !DILocalVariable(name: "a", scope: !7, file: !1, line: 10, type: !17)
!17 = !DICompositeType(tag: DW_TAG_array_type, baseType: !10, size: 320, elements: !18)
!18 = !{!19}
!19 = !DISubrange(count: 10)
!20 = !DILocalVariable(name: "b", scope: !7, file: !1, line: 11, type: !17)
!21 = !DILocalVariable(name: "i", scope: !22, file: !1, line: 13, type: !10)
!22 = distinct !DILexicalBlock(scope: !7, file: !1, line: 13, column: 3)
!23 = !DILocation(line: 0, scope: !7)
!24 = !DILocation(line: 10, column: 7, scope: !7)
!25 = !DILocation(line: 11, column: 7, scope: !7)
!26 = !DILocation(line: 0, scope: !22)
!27 = !DILocation(line: 13, column: 3, scope: !22)
!28 = !DILocation(line: 14, column: 5, scope: !29)
!29 = distinct !DILexicalBlock(scope: !30, file: !1, line: 13, column: 32)
!30 = distinct !DILexicalBlock(scope: !22, file: !1, line: 13, column: 3)
!31 = !DILocation(line: 14, column: 10, scope: !29)
!32 = !{!33, !33, i64 0}
!33 = !{!"int", !34, i64 0}
!34 = !{!"omnipotent char", !35, i64 0}
!35 = !{!"Simple C/C++ TBAA"}
!36 = !DILocation(line: 15, column: 5, scope: !29)
!37 = !DILocation(line: 15, column: 10, scope: !29)
!38 = !DILocation(line: 13, column: 27, scope: !30)
!39 = !DILocation(line: 13, column: 21, scope: !30)
!40 = distinct !{!40, !27, !41, !42}
!41 = !DILocation(line: 16, column: 3, scope: !22)
!42 = !{!"llvm.loop.unroll.disable"}
!43 = !DILocation(line: 18, column: 15, scope: !7)
!44 = !DILocation(line: 18, column: 10, scope: !7)
!45 = !DILocation(line: 18, column: 3, scope: !7)
