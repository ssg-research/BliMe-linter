; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; #include <stdint.h>
; 
; CHECK-LABEL: @simpleTest
; CHECK-NOT: select
; CHECK: ret i32
; int simpleTest(__attribute__((blinded)) int a) {
;   return a > 11 ? 45 : 78;
; }
; 
; CHECK-LABEL: @varReturns
; CHECK-NOT: select
; CHECK: ret i32
; int varReturns(__attribute__((blinded)) int a, int b, int c) {
;   return a > 11 ? b : c;
; }
; 
; char *moarTricky(__attribute__((blinded)) int a, char *b, char *c) {
;   return a > 11 ? b : c;
; }
; 
; Lets just ignore this...
; int get_number(int *);
; 
; CHECK-LABEL: @arrayMess
; CHECK-NOT: select
; CHECK: ret i32
; int arrayMess(__attribute__((blinded)) int cond) {
;   int a[10] = {1,2,3,4,5,6,7,8,9,0};
;   int b[10] = {0,9,8,7,6,5,4,3,2,1};
; 
;   int *param = cond > 10 ? a : b;
; 
;   return get_number(param);
; }
; 
; CHECK-LABEL: @arrayMess2
; CHECK-NOT: select
; CHECK: ret i32
; int arrayMess2(__attribute__((blinded)) int cond, int mod, int idx) {
;   int a[10] = {1,2,3,4,5,6,7,8,9,0};
;   int b[10] = {0,9,8,7,6,5,4,3,2,1};
; 
;   for (int i = 0; i < 10; ++i) {
;     a[i] += mod;
;     b[i] -= mod;
;   }
; 
;   return (cond > 10 ? a : b)[idx];
; }
; 
; struct failWhale { long d1; long d2; long d3; };
; 
; CHECK-LABEL: @structMesser
; CHECK-NOT: select
; CHECK: ret
; struct failWhale structMesser(__attribute__((blinded)) int cond,
;                               struct failWhale a, struct failWhale b) {
;   return cond > 10 ? a : b;
; }
; 
; void test1(uintptr_t);
; void test2(intptr_t);
; 
; CHECK-LABEL: @moarTricky2
; CHECK-NOT: select
; CHECK: ret i8*
; char *moarTricky2(__attribute__((blinded)) int a,
;                  __attribute__((blinded)) int cond, char *b, char *c) {
;   test1((uintptr_t) b);
;   test2((intptr_t) b);
;   return a > cond ? b : c;
; }



; ModuleID = 'BlindedComputation/Transforms/tranfrom-select.c'
source_filename = "BlindedComputation/Transforms/tranfrom-select.c"
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

%struct.failWhale = type { i64, i64, i64 }

@__const.arrayMess2.a = private unnamed_addr constant [10 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 0], align 16
@__const.arrayMess2.b = private unnamed_addr constant [10 x i32] [i32 0, i32 9, i32 8, i32 7, i32 6, i32 5, i32 4, i32 3, i32 2, i32 1], align 16

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i32 @simpleTest(i32 blinded %a) local_unnamed_addr #0 !dbg !13 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !18, metadata !DIExpression()), !dbg !19
  %cmp = icmp sgt i32 %a, 11, !dbg !20
  %cond = select i1 %cmp, i32 45, i32 78, !dbg !21
  ret i32 %cond, !dbg !22
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i32 @varReturns(i32 blinded %a, i32 %b, i32 %c) local_unnamed_addr #0 !dbg !23 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !27, metadata !DIExpression()), !dbg !30
  call void @llvm.dbg.value(metadata i32 %b, metadata !28, metadata !DIExpression()), !dbg !30
  call void @llvm.dbg.value(metadata i32 %c, metadata !29, metadata !DIExpression()), !dbg !30
  %cmp = icmp sgt i32 %a, 11, !dbg !31
  %cond = select i1 %cmp, i32 %b, i32 %c, !dbg !32
  ret i32 %cond, !dbg !33
}

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i8* @moarTricky(i32 blinded %a, i8* readnone %b, i8* readnone %c) local_unnamed_addr #0 !dbg !34 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !40, metadata !DIExpression()), !dbg !43
  call void @llvm.dbg.value(metadata i8* %b, metadata !41, metadata !DIExpression()), !dbg !43
  call void @llvm.dbg.value(metadata i8* %c, metadata !42, metadata !DIExpression()), !dbg !43
  %cmp = icmp sgt i32 %a, 11, !dbg !44
  %cond = select i1 %cmp, i8* %b, i8* %c, !dbg !45
  ret i8* %cond, !dbg !46
}

; Function Attrs: nounwind uwtable
define dso_local i32 @arrayMess(i32 blinded %cond) local_unnamed_addr #2 !dbg !47 {
entry:
  %a = alloca [10 x i32], align 16
  %b = alloca [10 x i32], align 16
  call void @llvm.dbg.value(metadata i32 %cond, metadata !49, metadata !DIExpression()), !dbg !57
  call void @llvm.dbg.declare(metadata [10 x i32]* %a, metadata !50, metadata !DIExpression()), !dbg !58
  %0 = bitcast [10 x i32]* %a to i8*, !dbg !58
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(40) %0, i8* nonnull align 16 dereferenceable(40) bitcast ([10 x i32]* @__const.arrayMess2.a to i8*), i64 40, i1 false), !dbg !58
  call void @llvm.dbg.declare(metadata [10 x i32]* %b, metadata !54, metadata !DIExpression()), !dbg !59
  %1 = bitcast [10 x i32]* %b to i8*, !dbg !59
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(40) %1, i8* nonnull align 16 dereferenceable(40) bitcast ([10 x i32]* @__const.arrayMess2.b to i8*), i64 40, i1 false), !dbg !59
  %cmp = icmp sgt i32 %cond, 10, !dbg !60
  %arraydecay = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 0, !dbg !61
  %arraydecay1 = getelementptr inbounds [10 x i32], [10 x i32]* %b, i64 0, i64 0, !dbg !61
  %cond2 = select i1 %cmp, i32* %arraydecay, i32* %arraydecay1, !dbg !61
  call void @llvm.dbg.value(metadata i32* %cond2, metadata !55, metadata !DIExpression()), !dbg !57
  %call = call i32 @get_number(i32* nonnull %cond2) #6, !dbg !62
  ret i32 %call, !dbg !63
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #3

declare !dbg !64 dso_local i32 @get_number(i32*) local_unnamed_addr #4

; Function Attrs: nounwind readnone uwtable
define dso_local i32 @arrayMess2(i32 blinded %cond, i32 %mod, i32 %idx) local_unnamed_addr #5 !dbg !67 {
entry:
  %a = alloca [10 x i32], align 16
  %b = alloca [10 x i32], align 16
  call void @llvm.dbg.value(metadata i32 %cond, metadata !69, metadata !DIExpression()), !dbg !76
  call void @llvm.dbg.value(metadata i32 %mod, metadata !70, metadata !DIExpression()), !dbg !76
  call void @llvm.dbg.value(metadata i32 %idx, metadata !71, metadata !DIExpression()), !dbg !76
  call void @llvm.dbg.declare(metadata [10 x i32]* %a, metadata !72, metadata !DIExpression()), !dbg !77
  %0 = bitcast [10 x i32]* %a to i8*, !dbg !77
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(40) %0, i8* nonnull align 16 dereferenceable(40) bitcast ([10 x i32]* @__const.arrayMess2.a to i8*), i64 40, i1 false), !dbg !77
  call void @llvm.dbg.declare(metadata [10 x i32]* %b, metadata !73, metadata !DIExpression()), !dbg !78
  %1 = bitcast [10 x i32]* %b to i8*, !dbg !78
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(40) %1, i8* nonnull align 16 dereferenceable(40) bitcast ([10 x i32]* @__const.arrayMess2.b to i8*), i64 40, i1 false), !dbg !78
  call void @llvm.dbg.value(metadata i32 0, metadata !74, metadata !DIExpression()), !dbg !79
  call void @llvm.dbg.value(metadata i64 0, metadata !74, metadata !DIExpression()), !dbg !79
  %arrayidx14 = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 0, !dbg !80
  %add15 = add nsw i32 %mod, 1, !dbg !83
  store i32 %add15, i32* %arrayidx14, align 16, !dbg !83, !tbaa !84
  %arrayidx216 = getelementptr inbounds [10 x i32], [10 x i32]* %b, i64 0, i64 0, !dbg !88
  %sub17 = sub nsw i32 0, %mod, !dbg !89
  store i32 %sub17, i32* %arrayidx216, align 16, !dbg !89, !tbaa !84
  call void @llvm.dbg.value(metadata i64 1, metadata !74, metadata !DIExpression()), !dbg !79
  br label %for.body.for.body_crit_edge, !dbg !90

for.body.for.body_crit_edge:                      ; preds = %entry, %for.body.for.body_crit_edge
  %indvars.iv.next18 = phi i64 [ 1, %entry ], [ %indvars.iv.next, %for.body.for.body_crit_edge ]
  %arrayidx.phi.trans.insert = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 %indvars.iv.next18, !dbg !91
  %.pre = load i32, i32* %arrayidx.phi.trans.insert, align 4, !dbg !83, !tbaa !84
  %arrayidx2.phi.trans.insert = getelementptr inbounds [10 x i32], [10 x i32]* %b, i64 0, i64 %indvars.iv.next18, !dbg !91
  %.pre13 = load i32, i32* %arrayidx2.phi.trans.insert, align 4, !dbg !89, !tbaa !84
  call void @llvm.dbg.value(metadata i64 %indvars.iv.next18, metadata !74, metadata !DIExpression()), !dbg !79
  %arrayidx = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 %indvars.iv.next18, !dbg !80
  %add = add nsw i32 %.pre, %mod, !dbg !83
  store i32 %add, i32* %arrayidx, align 4, !dbg !83, !tbaa !84
  %arrayidx2 = getelementptr inbounds [10 x i32], [10 x i32]* %b, i64 0, i64 %indvars.iv.next18, !dbg !88
  %sub = sub nsw i32 %.pre13, %mod, !dbg !89
  store i32 %sub, i32* %arrayidx2, align 4, !dbg !89, !tbaa !84
  %indvars.iv.next = add nuw nsw i64 %indvars.iv.next18, 1, !dbg !92
  call void @llvm.dbg.value(metadata i64 %indvars.iv.next, metadata !74, metadata !DIExpression()), !dbg !79
  %exitcond.not = icmp eq i64 %indvars.iv.next, 10, !dbg !93
  br i1 %exitcond.not, label %for.end, label %for.body.for.body_crit_edge, !dbg !90, !llvm.loop !94

for.end:                                          ; preds = %for.body.for.body_crit_edge
  %cmp3 = icmp sgt i32 %cond, 10, !dbg !97
  %arraydecay = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 0, !dbg !98
  %arraydecay4 = getelementptr inbounds [10 x i32], [10 x i32]* %b, i64 0, i64 0, !dbg !98
  %cond5 = select i1 %cmp3, i32* %arraydecay, i32* %arraydecay4, !dbg !98
  %idxprom6 = sext i32 %idx to i64, !dbg !99
  %arrayidx7 = getelementptr inbounds i32, i32* %cond5, i64 %idxprom6, !dbg !99
  %2 = load i32, i32* %arrayidx7, align 4, !dbg !99, !tbaa !84
  ret i32 %2, !dbg !100
}

; Function Attrs: nounwind uwtable
define dso_local void @structMesser(%struct.failWhale* noalias nocapture sret align 8 %agg.result, i32 blinded %cond, %struct.failWhale* nocapture readonly byval(%struct.failWhale) align 8 %a, %struct.failWhale* nocapture readonly byval(%struct.failWhale) align 8 %b) local_unnamed_addr #2 !dbg !101 {
entry:
  call void @llvm.dbg.value(metadata i32 %cond, metadata !110, metadata !DIExpression()), !dbg !113
  call void @llvm.dbg.declare(metadata %struct.failWhale* %a, metadata !111, metadata !DIExpression()), !dbg !114
  call void @llvm.dbg.declare(metadata %struct.failWhale* %b, metadata !112, metadata !DIExpression()), !dbg !115
  %cmp = icmp sgt i32 %cond, 10, !dbg !116
  %0 = bitcast %struct.failWhale* %agg.result to i8*, !dbg !113
  %b.sink = select i1 %cmp, %struct.failWhale* %a, %struct.failWhale* %b, !dbg !117
  %1 = bitcast %struct.failWhale* %b.sink to i8*, !dbg !113
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 8 dereferenceable(24) %0, i8* nonnull align 8 dereferenceable(24) %1, i64 24, i1 false), !dbg !113
  ret void, !dbg !118
}

; Function Attrs: nounwind uwtable
define dso_local i8* @moarTricky2(i32 blinded %a, i32 blinded %cond, i8* %b, i8* readnone %c) local_unnamed_addr #2 !dbg !119 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !123, metadata !DIExpression()), !dbg !127
  call void @llvm.dbg.value(metadata i32 %cond, metadata !124, metadata !DIExpression()), !dbg !127
  call void @llvm.dbg.value(metadata i8* %b, metadata !125, metadata !DIExpression()), !dbg !127
  call void @llvm.dbg.value(metadata i8* %c, metadata !126, metadata !DIExpression()), !dbg !127
  %0 = ptrtoint i8* %b to i64, !dbg !128
  tail call void @test1(i64 %0) #6, !dbg !129
  tail call void @test2(i64 %0) #6, !dbg !130
  %cmp = icmp sgt i32 %a, %cond, !dbg !131
  %cond1 = select i1 %cmp, i8* %b, i8* %c, !dbg !132
  ret i8* %cond1, !dbg !133
}

declare !dbg !134 dso_local void @test1(i64) local_unnamed_addr #4

declare !dbg !137 dso_local void @test2(i64) local_unnamed_addr #4

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }
attributes #2 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { argmemonly nounwind willreturn }
attributes #4 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #6 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!9, !10, !11}
!llvm.ident = !{!12}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, retainedTypes: !3, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "BlindedComputation/Transforms/tranfrom-select.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!2 = !{}
!3 = !{!4, !7}
!4 = !DIDerivedType(tag: DW_TAG_typedef, name: "uintptr_t", file: !5, line: 90, baseType: !6)
!5 = !DIFile(filename: "/usr/include/stdint.h", directory: "")
!6 = !DIBasicType(name: "long unsigned int", size: 64, encoding: DW_ATE_unsigned)
!7 = !DIDerivedType(tag: DW_TAG_typedef, name: "intptr_t", file: !5, line: 87, baseType: !8)
!8 = !DIBasicType(name: "long int", size: 64, encoding: DW_ATE_signed)
!9 = !{i32 7, !"Dwarf Version", i32 4}
!10 = !{i32 2, !"Debug Info Version", i32 3}
!11 = !{i32 1, !"wchar_size", i32 4}
!12 = !{!"clang version 11.0.0"}
!13 = distinct !DISubprogram(name: "simpleTest", scope: !1, file: !1, line: 7, type: !14, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !17)
!14 = !DISubroutineType(types: !15)
!15 = !{!16, !16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18}
!18 = !DILocalVariable(name: "a", arg: 1, scope: !13, file: !1, line: 7, type: !16)
!19 = !DILocation(line: 0, scope: !13)
!20 = !DILocation(line: 8, column: 12, scope: !13)
!21 = !DILocation(line: 8, column: 10, scope: !13)
!22 = !DILocation(line: 8, column: 3, scope: !13)
!23 = distinct !DISubprogram(name: "varReturns", scope: !1, file: !1, line: 14, type: !24, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !26)
!24 = !DISubroutineType(types: !25)
!25 = !{!16, !16, !16, !16}
!26 = !{!27, !28, !29}
!27 = !DILocalVariable(name: "a", arg: 1, scope: !23, file: !1, line: 14, type: !16)
!28 = !DILocalVariable(name: "b", arg: 2, scope: !23, file: !1, line: 14, type: !16)
!29 = !DILocalVariable(name: "c", arg: 3, scope: !23, file: !1, line: 14, type: !16)
!30 = !DILocation(line: 0, scope: !23)
!31 = !DILocation(line: 15, column: 12, scope: !23)
!32 = !DILocation(line: 15, column: 10, scope: !23)
!33 = !DILocation(line: 15, column: 3, scope: !23)
!34 = distinct !DISubprogram(name: "moarTricky", scope: !1, file: !1, line: 18, type: !35, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !39)
!35 = !DISubroutineType(types: !36)
!36 = !{!37, !16, !37, !37}
!37 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !38, size: 64)
!38 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!39 = !{!40, !41, !42}
!40 = !DILocalVariable(name: "a", arg: 1, scope: !34, file: !1, line: 18, type: !16)
!41 = !DILocalVariable(name: "b", arg: 2, scope: !34, file: !1, line: 18, type: !37)
!42 = !DILocalVariable(name: "c", arg: 3, scope: !34, file: !1, line: 18, type: !37)
!43 = !DILocation(line: 0, scope: !34)
!44 = !DILocation(line: 19, column: 12, scope: !34)
!45 = !DILocation(line: 19, column: 10, scope: !34)
!46 = !DILocation(line: 19, column: 3, scope: !34)
!47 = distinct !DISubprogram(name: "arrayMess", scope: !1, file: !1, line: 28, type: !14, scopeLine: 28, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !48)
!48 = !{!49, !50, !54, !55}
!49 = !DILocalVariable(name: "cond", arg: 1, scope: !47, file: !1, line: 28, type: !16)
!50 = !DILocalVariable(name: "a", scope: !47, file: !1, line: 29, type: !51)
!51 = !DICompositeType(tag: DW_TAG_array_type, baseType: !16, size: 320, elements: !52)
!52 = !{!53}
!53 = !DISubrange(count: 10)
!54 = !DILocalVariable(name: "b", scope: !47, file: !1, line: 30, type: !51)
!55 = !DILocalVariable(name: "param", scope: !47, file: !1, line: 32, type: !56)
!56 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64)
!57 = !DILocation(line: 0, scope: !47)
!58 = !DILocation(line: 29, column: 7, scope: !47)
!59 = !DILocation(line: 30, column: 7, scope: !47)
!60 = !DILocation(line: 32, column: 21, scope: !47)
!61 = !DILocation(line: 32, column: 16, scope: !47)
!62 = !DILocation(line: 34, column: 10, scope: !47)
!63 = !DILocation(line: 34, column: 3, scope: !47)
!64 = !DISubprogram(name: "get_number", scope: !1, file: !1, line: 23, type: !65, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!65 = !DISubroutineType(types: !66)
!66 = !{!16, !56}
!67 = distinct !DISubprogram(name: "arrayMess2", scope: !1, file: !1, line: 40, type: !24, scopeLine: 40, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !68)
!68 = !{!69, !70, !71, !72, !73, !74}
!69 = !DILocalVariable(name: "cond", arg: 1, scope: !67, file: !1, line: 40, type: !16)
!70 = !DILocalVariable(name: "mod", arg: 2, scope: !67, file: !1, line: 40, type: !16)
!71 = !DILocalVariable(name: "idx", arg: 3, scope: !67, file: !1, line: 40, type: !16)
!72 = !DILocalVariable(name: "a", scope: !67, file: !1, line: 41, type: !51)
!73 = !DILocalVariable(name: "b", scope: !67, file: !1, line: 42, type: !51)
!74 = !DILocalVariable(name: "i", scope: !75, file: !1, line: 44, type: !16)
!75 = distinct !DILexicalBlock(scope: !67, file: !1, line: 44, column: 3)
!76 = !DILocation(line: 0, scope: !67)
!77 = !DILocation(line: 41, column: 7, scope: !67)
!78 = !DILocation(line: 42, column: 7, scope: !67)
!79 = !DILocation(line: 0, scope: !75)
!80 = !DILocation(line: 45, column: 5, scope: !81)
!81 = distinct !DILexicalBlock(scope: !82, file: !1, line: 44, column: 32)
!82 = distinct !DILexicalBlock(scope: !75, file: !1, line: 44, column: 3)
!83 = !DILocation(line: 45, column: 10, scope: !81)
!84 = !{!85, !85, i64 0}
!85 = !{!"int", !86, i64 0}
!86 = !{!"omnipotent char", !87, i64 0}
!87 = !{!"Simple C/C++ TBAA"}
!88 = !DILocation(line: 46, column: 5, scope: !81)
!89 = !DILocation(line: 46, column: 10, scope: !81)
!90 = !DILocation(line: 44, column: 3, scope: !75)
!91 = !DILocation(line: 0, scope: !81)
!92 = !DILocation(line: 44, column: 27, scope: !82)
!93 = !DILocation(line: 44, column: 21, scope: !82)
!94 = distinct !{!94, !90, !95, !96}
!95 = !DILocation(line: 47, column: 3, scope: !75)
!96 = !{!"llvm.loop.unroll.disable"}
!97 = !DILocation(line: 49, column: 16, scope: !67)
!98 = !DILocation(line: 49, column: 11, scope: !67)
!99 = !DILocation(line: 49, column: 10, scope: !67)
!100 = !DILocation(line: 49, column: 3, scope: !67)
!101 = distinct !DISubprogram(name: "structMesser", scope: !1, file: !1, line: 57, type: !102, scopeLine: 58, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !109)
!102 = !DISubroutineType(types: !103)
!103 = !{!104, !16, !104, !104}
!104 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "failWhale", file: !1, line: 52, size: 192, elements: !105)
!105 = !{!106, !107, !108}
!106 = !DIDerivedType(tag: DW_TAG_member, name: "d1", scope: !104, file: !1, line: 52, baseType: !8, size: 64)
!107 = !DIDerivedType(tag: DW_TAG_member, name: "d2", scope: !104, file: !1, line: 52, baseType: !8, size: 64, offset: 64)
!108 = !DIDerivedType(tag: DW_TAG_member, name: "d3", scope: !104, file: !1, line: 52, baseType: !8, size: 64, offset: 128)
!109 = !{!110, !111, !112}
!110 = !DILocalVariable(name: "cond", arg: 1, scope: !101, file: !1, line: 57, type: !16)
!111 = !DILocalVariable(name: "a", arg: 2, scope: !101, file: !1, line: 58, type: !104)
!112 = !DILocalVariable(name: "b", arg: 3, scope: !101, file: !1, line: 58, type: !104)
!113 = !DILocation(line: 0, scope: !101)
!114 = !DILocation(line: 58, column: 48, scope: !101)
!115 = !DILocation(line: 58, column: 68, scope: !101)
!116 = !DILocation(line: 59, column: 15, scope: !101)
!117 = !DILocation(line: 59, column: 10, scope: !101)
!118 = !DILocation(line: 59, column: 3, scope: !101)
!119 = distinct !DISubprogram(name: "moarTricky2", scope: !1, file: !1, line: 68, type: !120, scopeLine: 69, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !122)
!120 = !DISubroutineType(types: !121)
!121 = !{!37, !16, !16, !37, !37}
!122 = !{!123, !124, !125, !126}
!123 = !DILocalVariable(name: "a", arg: 1, scope: !119, file: !1, line: 68, type: !16)
!124 = !DILocalVariable(name: "cond", arg: 2, scope: !119, file: !1, line: 69, type: !16)
!125 = !DILocalVariable(name: "b", arg: 3, scope: !119, file: !1, line: 69, type: !37)
!126 = !DILocalVariable(name: "c", arg: 4, scope: !119, file: !1, line: 69, type: !37)
!127 = !DILocation(line: 0, scope: !119)
!128 = !DILocation(line: 70, column: 9, scope: !119)
!129 = !DILocation(line: 70, column: 3, scope: !119)
!130 = !DILocation(line: 71, column: 3, scope: !119)
!131 = !DILocation(line: 72, column: 12, scope: !119)
!132 = !DILocation(line: 72, column: 10, scope: !119)
!133 = !DILocation(line: 72, column: 3, scope: !119)
!134 = !DISubprogram(name: "test1", scope: !1, file: !1, line: 62, type: !135, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!135 = !DISubroutineType(types: !136)
!136 = !{null, !6}
!137 = !DISubprogram(name: "test2", scope: !1, file: !1, line: 63, type: !138, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!138 = !DISubroutineType(types: !139)
!139 = !{null, !8}
