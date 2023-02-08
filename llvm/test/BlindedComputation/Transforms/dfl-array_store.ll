; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
;
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
;

; CFLAGS: --target=x86_64 -I/usr/include/x86_64-linux-gnu -Wall -O1 -Xclang -disable-lifetime-markers -fno-discard-value-names -fno-unroll-loops -gdwarf

; #include <stdint.h>
; #include <stdio.h>
;
; void modify_array(intptr_t *);
; void modify_array4(intptr_t arg[2][5]);
;
; CHECK-NOT: storeInstr with a blinded pointer!
; intptr_t blinded_access(__attribute__((blinded)) intptr_t blinded_i, int ts) {
;   // intptr_t a[10] = {1,2,3,4,5,6,7,8,9,0};
;
;   // a[blinded_i] = 20;
;   // // Make sure the compiler cannot know what a contains!
;   ts = ts * 7;
;   // modify_array(a);
;   intptr_t a[2][5] = {{0, 1, 2, 3, 4}, {5, 6, 7, 8, 9}};
;   a[blinded_i][blinded_i] = ts;
;   modify_array4(a);
;
;   if (ts > 128) {
;     printf("done");
;   }
;
;   return a[1][1];
; }



; ModuleID = 'BlindedComputation/Transforms/dfl-array_store.c'
source_filename = "BlindedComputation/Transforms/dfl-array_store.c"
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

@__const.blinded_access.a = private unnamed_addr constant [2 x [5 x i64]] [[5 x i64] [i64 0, i64 1, i64 2, i64 3, i64 4], [5 x i64] [i64 5, i64 6, i64 7, i64 8, i64 9]], align 16
@.str = private unnamed_addr constant [5 x i8] c"done\00", align 1

; Function Attrs: nounwind uwtable
define dso_local i64 @blinded_access(i64 blinded %blinded_i, i32 %ts) local_unnamed_addr #0 !dbg !7 {
entry:
  %a = alloca [2 x [5 x i64]], align 16
  call void @llvm.dbg.value(metadata i64 %blinded_i, metadata !15, metadata !DIExpression()), !dbg !22
  call void @llvm.dbg.value(metadata i32 %ts, metadata !16, metadata !DIExpression()), !dbg !22
  %mul = mul nsw i32 %ts, 7, !dbg !23
  call void @llvm.dbg.value(metadata i32 %mul, metadata !16, metadata !DIExpression()), !dbg !22
  call void @llvm.dbg.declare(metadata [2 x [5 x i64]]* %a, metadata !17, metadata !DIExpression()), !dbg !24
  %0 = bitcast [2 x [5 x i64]]* %a to i8*, !dbg !24
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 16 dereferenceable(80) %0, i8* nonnull align 16 dereferenceable(80) bitcast ([2 x [5 x i64]]* @__const.blinded_access.a to i8*), i64 80, i1 false), !dbg !24
  %conv = sext i32 %mul to i64, !dbg !25
  %arrayidx1 = getelementptr inbounds [2 x [5 x i64]], [2 x [5 x i64]]* %a, i64 0, i64 %blinded_i, i64 %blinded_i, !dbg !26
  store i64 %conv, i64* %arrayidx1, align 8, !dbg !27, !tbaa !28
  %arraydecay = getelementptr inbounds [2 x [5 x i64]], [2 x [5 x i64]]* %a, i64 0, i64 0, !dbg !32
  call void @modify_array4([5 x i64]* nonnull %arraydecay) #5, !dbg !33
  %cmp = icmp sgt i32 %mul, 128, !dbg !34
  br i1 %cmp, label %if.then, label %if.end, !dbg !36

if.then:                                          ; preds = %entry
  %call = call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([5 x i8], [5 x i8]* @.str, i64 0, i64 0)), !dbg !37
  br label %if.end, !dbg !39

if.end:                                           ; preds = %if.then, %entry
  %arrayidx4 = getelementptr inbounds [2 x [5 x i64]], [2 x [5 x i64]]* %a, i64 0, i64 1, i64 1, !dbg !40
  %1 = load i64, i64* %arrayidx4, align 8, !dbg !40, !tbaa !28
  ret i64 %1, !dbg !41
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #2

declare !dbg !42 dso_local void @modify_array4([5 x i64]*) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare dso_local i32 @printf(i8* nocapture readonly, ...) local_unnamed_addr #4

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }
attributes #2 = { argmemonly nounwind willreturn }
attributes #3 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nofree nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4, !5}
!llvm.ident = !{!6}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "BlindedComputation/Transforms/dfl-array_store.c", directory: "")
!2 = !{}
!3 = !{i32 7, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = !{i32 1, !"wchar_size", i32 4}
!6 = !{!"clang version 11.0.0"}
!7 = distinct !DISubprogram(name: "blinded_access", scope: !1, file: !1, line: 14, type: !8, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !14)
!8 = !DISubroutineType(types: !9)
!9 = !{!10, !10, !13}
!10 = !DIDerivedType(tag: DW_TAG_typedef, name: "intptr_t", file: !11, line: 87, baseType: !12)
!11 = !DIFile(filename: "/usr/include/stdint.h", directory: "")
!12 = !DIBasicType(name: "long int", size: 64, encoding: DW_ATE_signed)
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "blinded_i", arg: 1, scope: !7, file: !1, line: 14, type: !10)
!16 = !DILocalVariable(name: "ts", arg: 2, scope: !7, file: !1, line: 14, type: !13)
!17 = !DILocalVariable(name: "a", scope: !7, file: !1, line: 21, type: !18)
!18 = !DICompositeType(tag: DW_TAG_array_type, baseType: !10, size: 640, elements: !19)
!19 = !{!20, !21}
!20 = !DISubrange(count: 2)
!21 = !DISubrange(count: 5)
!22 = !DILocation(line: 0, scope: !7)
!23 = !DILocation(line: 19, column: 11, scope: !7)
!24 = !DILocation(line: 21, column: 12, scope: !7)
!25 = !DILocation(line: 22, column: 29, scope: !7)
!26 = !DILocation(line: 22, column: 3, scope: !7)
!27 = !DILocation(line: 22, column: 27, scope: !7)
!28 = !{!29, !29, i64 0}
!29 = !{!"long", !30, i64 0}
!30 = !{!"omnipotent char", !31, i64 0}
!31 = !{!"Simple C/C++ TBAA"}
!32 = !DILocation(line: 23, column: 17, scope: !7)
!33 = !DILocation(line: 23, column: 3, scope: !7)
!34 = !DILocation(line: 25, column: 10, scope: !35)
!35 = distinct !DILexicalBlock(scope: !7, file: !1, line: 25, column: 7)
!36 = !DILocation(line: 25, column: 7, scope: !7)
!37 = !DILocation(line: 26, column: 5, scope: !38)
!38 = distinct !DILexicalBlock(scope: !35, file: !1, line: 25, column: 17)
!39 = !DILocation(line: 27, column: 3, scope: !38)
!40 = !DILocation(line: 29, column: 10, scope: !7)
!41 = !DILocation(line: 29, column: 3, scope: !7)
!42 = !DISubprogram(name: "modify_array4", scope: !1, file: !1, line: 7, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !2)
!43 = !DISubroutineType(types: !44)
!44 = !{null, !45}
!45 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !46, size: 64)
!46 = !DICompositeType(tag: DW_TAG_array_type, baseType: !12, size: 320, elements: !47)
!47 = !{!21}
