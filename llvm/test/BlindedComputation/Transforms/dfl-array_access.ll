; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s --check-prefixes=CHKALL,CHECK
; RUN: opt -O1 -S < %s | FileCheck %s --check-prefixes=CHKALL,NOINSTR
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -I/usr/include/x86_64-linux-gnu -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; #include <stdint.h>
; 
; void modify_array(intptr_t *);
; 
; CHECK-LABEL: @blinded_access
; CHECK: call void @modify_array
; NOINSTR: getelementptr inbounds [10 x i64], [10 x i64]* %a, i64 0, i64 %blinded_i
; CHECK-NOT: getelementptr inbounds [10 x i64], [10 x i64]* %a, i64 0, i64 %blinded_i
; CHECK: ret i64
; intptr_t blinded_access(__attribute__((blinded)) intptr_t blinded_i) {
;   intptr_t a[10] = {1,2,3,4,5,6,7,8,9,0};
; 
;   // Make sure the compiler cannot know what a contains!
;   modify_array(a);
; 
;   return a[blinded_i];
; }



; ModuleID = 'BlindedComputation/Transforms/dfl-array_access.c'
source_filename = "BlindedComputation/Transforms/dfl-array_access.c"
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

@__const.blinded_access.a = private unnamed_addr constant [10 x i64] [i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7, i64 8, i64 9, i64 0], align 16

; Function Attrs: nounwind uwtable
define dso_local i64 @blinded_access(i64 blinded %blinded_i) local_unnamed_addr #0 !dbg !7 {
entry:
  %a = alloca [10 x i64], align 16
  call void @llvm.dbg.value(metadata i64 %blinded_i, metadata !14, metadata !DIExpression()), !dbg !19
  call void @llvm.dbg.declare(metadata [10 x i64]* %a, metadata !15, metadata !DIExpression()), !dbg !20
  %0 = bitcast [10 x i64]* %a to i8*, !dbg !20
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(80) %0, i8* nonnull align 16 dereferenceable(80) bitcast ([10 x i64]* @__const.blinded_access.a to i8*), i64 80, i1 false), !dbg !20
  %arraydecay = getelementptr inbounds [10 x i64], [10 x i64]* %a, i64 0, i64 0, !dbg !21
  call void @modify_array(i64* nonnull %arraydecay) #4, !dbg !22
  %arrayidx = getelementptr inbounds [10 x i64], [10 x i64]* %a, i64 0, i64 %blinded_i, !dbg !23
  %1 = load i64, i64* %arrayidx, align 8, !dbg !23, !tbaa !24
  ret i64 %1, !dbg !28
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #2

declare !dbg !29 dso_local void @modify_array(i64*) local_unnamed_addr #3

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }
attributes #2 = { argmemonly nounwind willreturn }
attributes #3 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4, !5}
!llvm.ident = !{!6}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "BlindedComputation/Transforms/dfl-array_access.c", directory: "")
!2 = !{}
!3 = !{i32 7, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = !{i32 1, !"wchar_size", i32 4}
!6 = !{!"clang version 11.0.0"}
!7 = distinct !DISubprogram(name: "blinded_access", scope: !1, file: !1, line: 12, type: !8, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !13)
!8 = !DISubroutineType(types: !9)
!9 = !{!10, !10}
!10 = !DIDerivedType(tag: DW_TAG_typedef, name: "intptr_t", file: !11, line: 87, baseType: !12)
!11 = !DIFile(filename: "/usr/include/stdint.h", directory: "")
!12 = !DIBasicType(name: "long int", size: 64, encoding: DW_ATE_signed)
!13 = !{!14, !15}
!14 = !DILocalVariable(name: "blinded_i", arg: 1, scope: !7, file: !1, line: 12, type: !10)
!15 = !DILocalVariable(name: "a", scope: !7, file: !1, line: 13, type: !16)
!16 = !DICompositeType(tag: DW_TAG_array_type, baseType: !10, size: 640, elements: !17)
!17 = !{!18}
!18 = !DISubrange(count: 10)
!19 = !DILocation(line: 0, scope: !7)
!20 = !DILocation(line: 13, column: 12, scope: !7)
!21 = !DILocation(line: 16, column: 16, scope: !7)
!22 = !DILocation(line: 16, column: 3, scope: !7)
!23 = !DILocation(line: 18, column: 10, scope: !7)
!24 = !{!25, !25, i64 0}
!25 = !{!"long", !26, i64 0}
!26 = !{!"omnipotent char", !27, i64 0}
!27 = !{!"Simple C/C++ TBAA"}
!28 = !DILocation(line: 18, column: 3, scope: !7)
!29 = !DISubprogram(name: "modify_array", scope: !1, file: !1, line: 5, type: !30, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!30 = !DISubroutineType(types: !31)
!31 = !{null, !32}
!32 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !12, size: 64)
