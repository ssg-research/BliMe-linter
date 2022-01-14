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

@__const.arrayMess.a = private unnamed_addr constant [10 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 0], align 16
@__const.arrayMess.b = private unnamed_addr constant [10 x i32] [i32 0, i32 9, i32 8, i32 7, i32 6, i32 5, i32 4, i32 3, i32 2, i32 1], align 16

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
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(40) %0, i8* nonnull align 16 dereferenceable(40) bitcast ([10 x i32]* @__const.arrayMess.a to i8*), i64 40, i1 false), !dbg !58
  call void @llvm.dbg.declare(metadata [10 x i32]* %b, metadata !54, metadata !DIExpression()), !dbg !59
  %1 = bitcast [10 x i32]* %b to i8*, !dbg !59
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(40) %1, i8* nonnull align 16 dereferenceable(40) bitcast ([10 x i32]* @__const.arrayMess.b to i8*), i64 40, i1 false), !dbg !59
  %cmp = icmp sgt i32 %cond, 10, !dbg !60
  %arraydecay = getelementptr inbounds [10 x i32], [10 x i32]* %a, i64 0, i64 0, !dbg !61
  %arraydecay1 = getelementptr inbounds [10 x i32], [10 x i32]* %b, i64 0, i64 0, !dbg !61
  %cond2 = select i1 %cmp, i32* %arraydecay, i32* %arraydecay1, !dbg !61
  call void @llvm.dbg.value(metadata i32* %cond2, metadata !55, metadata !DIExpression()), !dbg !57
  %call = call i32 @get_number(i32* nonnull %cond2) #5, !dbg !62
  ret i32 %call, !dbg !63
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #3

declare !dbg !64 dso_local i32 @get_number(i32*) local_unnamed_addr #4

; Function Attrs: nounwind uwtable
define dso_local void @structMesser(%struct.failWhale* noalias nocapture sret align 8 %agg.result, i32 blinded %cond, %struct.failWhale* nocapture readonly byval(%struct.failWhale) align 8 %a, %struct.failWhale* nocapture readonly byval(%struct.failWhale) align 8 %b) local_unnamed_addr #2 !dbg !67 {
entry:
  call void @llvm.dbg.value(metadata i32 %cond, metadata !76, metadata !DIExpression()), !dbg !79
  call void @llvm.dbg.declare(metadata %struct.failWhale* %a, metadata !77, metadata !DIExpression()), !dbg !80
  call void @llvm.dbg.declare(metadata %struct.failWhale* %b, metadata !78, metadata !DIExpression()), !dbg !81
  %cmp = icmp sgt i32 %cond, 10, !dbg !82
  %0 = bitcast %struct.failWhale* %agg.result to i8*, !dbg !79
  %b.sink = select i1 %cmp, %struct.failWhale* %a, %struct.failWhale* %b, !dbg !83
  %1 = bitcast %struct.failWhale* %b.sink to i8*, !dbg !79
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 8 dereferenceable(24) %0, i8* nonnull align 8 dereferenceable(24) %1, i64 24, i1 false), !dbg !79
  ret void, !dbg !84
}

; Function Attrs: nounwind uwtable
define dso_local i8* @moarTricky2(i32 blinded %a, i32 blinded %cond, i8* %b, i8* readnone %c) local_unnamed_addr #2 !dbg !85 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !89, metadata !DIExpression()), !dbg !93
  call void @llvm.dbg.value(metadata i32 %cond, metadata !90, metadata !DIExpression()), !dbg !93
  call void @llvm.dbg.value(metadata i8* %b, metadata !91, metadata !DIExpression()), !dbg !93
  call void @llvm.dbg.value(metadata i8* %c, metadata !92, metadata !DIExpression()), !dbg !93
  %0 = ptrtoint i8* %b to i64, !dbg !94
  tail call void @test1(i64 %0) #5, !dbg !95
  tail call void @test2(i64 %0) #5, !dbg !96
  %cmp = icmp sgt i32 %a, %cond, !dbg !97
  %cond1 = select i1 %cmp, i8* %b, i8* %c, !dbg !98
  ret i8* %cond1, !dbg !99
}

declare !dbg !100 dso_local void @test1(i64) local_unnamed_addr #4

declare !dbg !103 dso_local void @test2(i64) local_unnamed_addr #4

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }
attributes #2 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { argmemonly nounwind willreturn }
attributes #4 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!9, !10, !11}
!llvm.ident = !{!12}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, retainedTypes: !3, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "BlindedComputation/Transforms/tranfrom-select.c", directory: "/home/hester/Desktop/bc-llvm/bc/llvm-test")
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
!67 = distinct !DISubprogram(name: "structMesser", scope: !1, file: !1, line: 42, type: !68, scopeLine: 43, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !75)
!68 = !DISubroutineType(types: !69)
!69 = !{!70, !16, !70, !70}
!70 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "failWhale", file: !1, line: 37, size: 192, elements: !71)
!71 = !{!72, !73, !74}
!72 = !DIDerivedType(tag: DW_TAG_member, name: "d1", scope: !70, file: !1, line: 37, baseType: !8, size: 64)
!73 = !DIDerivedType(tag: DW_TAG_member, name: "d2", scope: !70, file: !1, line: 37, baseType: !8, size: 64, offset: 64)
!74 = !DIDerivedType(tag: DW_TAG_member, name: "d3", scope: !70, file: !1, line: 37, baseType: !8, size: 64, offset: 128)
!75 = !{!76, !77, !78}
!76 = !DILocalVariable(name: "cond", arg: 1, scope: !67, file: !1, line: 42, type: !16)
!77 = !DILocalVariable(name: "a", arg: 2, scope: !67, file: !1, line: 43, type: !70)
!78 = !DILocalVariable(name: "b", arg: 3, scope: !67, file: !1, line: 43, type: !70)
!79 = !DILocation(line: 0, scope: !67)
!80 = !DILocation(line: 43, column: 48, scope: !67)
!81 = !DILocation(line: 43, column: 68, scope: !67)
!82 = !DILocation(line: 44, column: 15, scope: !67)
!83 = !DILocation(line: 44, column: 10, scope: !67)
!84 = !DILocation(line: 44, column: 3, scope: !67)
!85 = distinct !DISubprogram(name: "moarTricky2", scope: !1, file: !1, line: 53, type: !86, scopeLine: 54, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !88)
!86 = !DISubroutineType(types: !87)
!87 = !{!37, !16, !16, !37, !37}
!88 = !{!89, !90, !91, !92}
!89 = !DILocalVariable(name: "a", arg: 1, scope: !85, file: !1, line: 53, type: !16)
!90 = !DILocalVariable(name: "cond", arg: 2, scope: !85, file: !1, line: 54, type: !16)
!91 = !DILocalVariable(name: "b", arg: 3, scope: !85, file: !1, line: 54, type: !37)
!92 = !DILocalVariable(name: "c", arg: 4, scope: !85, file: !1, line: 54, type: !37)
!93 = !DILocation(line: 0, scope: !85)
!94 = !DILocation(line: 55, column: 9, scope: !85)
!95 = !DILocation(line: 55, column: 3, scope: !85)
!96 = !DILocation(line: 56, column: 3, scope: !85)
!97 = !DILocation(line: 57, column: 12, scope: !85)
!98 = !DILocation(line: 57, column: 10, scope: !85)
!99 = !DILocation(line: 57, column: 3, scope: !85)
!100 = !DISubprogram(name: "test1", scope: !1, file: !1, line: 47, type: !101, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!101 = !DISubroutineType(types: !102)
!102 = !{null, !6}
!103 = !DISubprogram(name: "test2", scope: !1, file: !1, line: 48, type: !104, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!104 = !DISubroutineType(types: !105)
!105 = !{null, !8}
