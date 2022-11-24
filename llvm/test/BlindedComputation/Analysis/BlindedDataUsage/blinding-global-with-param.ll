; RUN: opt -passes="print<blinded-data-usage>" -S -disable-output < %s 2>&1 | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -I/usr/include/x86_64-linux-gnu -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; 
; #include <stddef.h>
; 
; #define noinline __attribute__((noinline))
; 
; int out;
; 
; noinline void move_blinded(__attribute__((blinded)) int blinded_in) {
; 	out =  blinded_in;
; }
; 
; CHECK: loadInstr with a blinded pointer!
; CHECK: %2 = load i8, i8* %arrayidx1
; int main(int argc, char **argv) {
; 	move_blinded(argc);
; 	
; 	return argv[0][argc + out];
; }



; ModuleID = 'BlindedComputation/Analysis/BlindedDataUsage/blinding-global-with-param.c'
source_filename = "BlindedComputation/Analysis/BlindedDataUsage/blinding-global-with-param.c"
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

@out = dso_local local_unnamed_addr global i32 0, align 4, !dbg !0

; Function Attrs: nofree noinline norecurse nounwind uwtable writeonly
define dso_local void @move_blinded(i32 blinded %blinded_in) local_unnamed_addr #0 !dbg !11 {
entry:
  call void @llvm.dbg.value(metadata i32 %blinded_in, metadata !15, metadata !DIExpression()), !dbg !16
  store i32 %blinded_in, i32* @out, align 4, !dbg !17, !tbaa !18
  ret void, !dbg !22
}

; Function Attrs: nofree norecurse nounwind uwtable
define dso_local i32 @main(i32 %argc, i8** nocapture readonly %argv) local_unnamed_addr #1 !dbg !23 {
entry:
  call void @llvm.dbg.value(metadata i32 %argc, metadata !30, metadata !DIExpression()), !dbg !32
  call void @llvm.dbg.value(metadata i8** %argv, metadata !31, metadata !DIExpression()), !dbg !32
  tail call void @move_blinded(i32 %argc), !dbg !33
  %0 = load i8*, i8** %argv, align 8, !dbg !34, !tbaa !35
  %1 = load i32, i32* @out, align 4, !dbg !37, !tbaa !18
  %add = add nsw i32 %1, %argc, !dbg !38
  %idxprom = sext i32 %add to i64, !dbg !34
  %arrayidx1 = getelementptr inbounds i8, i8* %0, i64 %idxprom, !dbg !34
  %2 = load i8, i8* %arrayidx1, align 1, !dbg !34, !tbaa !39
  %conv = sext i8 %2 to i32, !dbg !34
  ret i32 %conv, !dbg !40
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #2

attributes #0 = { nofree noinline norecurse nounwind uwtable writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nofree norecurse nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!7, !8, !9}
!llvm.ident = !{!10}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "out", scope: !2, file: !3, line: 7, type: !6, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Analysis/BlindedDataUsage/blinding-global-with-param.c", directory: "")
!4 = !{}
!5 = !{!0}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = !{i32 7, !"Dwarf Version", i32 4}
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 1, !"wchar_size", i32 4}
!10 = !{!"clang version 11.0.0"}
!11 = distinct !DISubprogram(name: "move_blinded", scope: !3, file: !3, line: 9, type: !12, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !14)
!12 = !DISubroutineType(types: !13)
!13 = !{null, !6}
!14 = !{!15}
!15 = !DILocalVariable(name: "blinded_in", arg: 1, scope: !11, file: !3, line: 9, type: !6)
!16 = !DILocation(line: 0, scope: !11)
!17 = !DILocation(line: 10, column: 6, scope: !11)
!18 = !{!19, !19, i64 0}
!19 = !{!"int", !20, i64 0}
!20 = !{!"omnipotent char", !21, i64 0}
!21 = !{!"Simple C/C++ TBAA"}
!22 = !DILocation(line: 11, column: 1, scope: !11)
!23 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 15, type: !24, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !29)
!24 = !DISubroutineType(types: !25)
!25 = !{!6, !6, !26}
!26 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !27, size: 64)
!27 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !28, size: 64)
!28 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!29 = !{!30, !31}
!30 = !DILocalVariable(name: "argc", arg: 1, scope: !23, file: !3, line: 15, type: !6)
!31 = !DILocalVariable(name: "argv", arg: 2, scope: !23, file: !3, line: 15, type: !26)
!32 = !DILocation(line: 0, scope: !23)
!33 = !DILocation(line: 16, column: 2, scope: !23)
!34 = !DILocation(line: 18, column: 9, scope: !23)
!35 = !{!36, !36, i64 0}
!36 = !{!"any pointer", !20, i64 0}
!37 = !DILocation(line: 18, column: 24, scope: !23)
!38 = !DILocation(line: 18, column: 22, scope: !23)
!39 = !{!20, !20, i64 0}
!40 = !DILocation(line: 18, column: 2, scope: !23)
