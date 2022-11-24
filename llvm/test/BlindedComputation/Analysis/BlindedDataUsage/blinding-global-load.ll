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
; __attribute__((blinded)) int blinded_in;
; 
; noinline void move_blinded(void) {
; 	out =  blinded_in;
; }
; 
; CHECK: loadInstr with a blinded pointer!
; CHECK: %2 = load i8, i8* %arrayidx1
; int main(int argc, char **argv) {
; 	move_blinded();
; 	
; 	return argv[0][argc + out];
; }



; ModuleID = 'BlindedComputation/Analysis/BlindedDataUsage/blinding-global-load.c'
source_filename = "BlindedComputation/Analysis/BlindedDataUsage/blinding-global-load.c"
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

@blinded_in = dso_local local_unnamed_addr global i32 0, align 4, !dbg !0 #0
@out = dso_local local_unnamed_addr global i32 0, align 4, !dbg !6

; Function Attrs: nofree noinline norecurse nounwind uwtable
define dso_local void @move_blinded() local_unnamed_addr #1 !dbg !13 {
entry:
  %0 = load i32, i32* @blinded_in, align 4, !dbg !16, !tbaa !17
  store i32 %0, i32* @out, align 4, !dbg !21, !tbaa !17
  ret void, !dbg !22
}

; Function Attrs: nofree norecurse nounwind uwtable
define dso_local i32 @main(i32 %argc, i8** nocapture readonly %argv) local_unnamed_addr #2 !dbg !23 {
entry:
  call void @llvm.dbg.value(metadata i32 %argc, metadata !30, metadata !DIExpression()), !dbg !32
  call void @llvm.dbg.value(metadata i8** %argv, metadata !31, metadata !DIExpression()), !dbg !32
  tail call void @move_blinded(), !dbg !33
  %0 = load i8*, i8** %argv, align 8, !dbg !34, !tbaa !35
  %1 = load i32, i32* @out, align 4, !dbg !37, !tbaa !17
  %add = add nsw i32 %1, %argc, !dbg !38
  %idxprom = sext i32 %add to i64, !dbg !34
  %arrayidx1 = getelementptr inbounds i8, i8* %0, i64 %idxprom, !dbg !34
  %2 = load i8, i8* %arrayidx1, align 1, !dbg !34, !tbaa !39
  %conv = sext i8 %2 to i32, !dbg !34
  ret i32 %conv, !dbg !40
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { blinded }
attributes #1 = { nofree noinline norecurse nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree norecurse nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!9, !10, !11}
!llvm.ident = !{!12}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "blinded_in", scope: !2, file: !3, line: 8, type: !8, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Analysis/BlindedDataUsage/blinding-global-load.c", directory: "")
!4 = !{}
!5 = !{!6, !0}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "out", scope: !2, file: !3, line: 7, type: !8, isLocal: false, isDefinition: true)
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!9 = !{i32 7, !"Dwarf Version", i32 4}
!10 = !{i32 2, !"Debug Info Version", i32 3}
!11 = !{i32 1, !"wchar_size", i32 4}
!12 = !{!"clang version 11.0.0"}
!13 = distinct !DISubprogram(name: "move_blinded", scope: !3, file: !3, line: 10, type: !14, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!14 = !DISubroutineType(types: !15)
!15 = !{null}
!16 = !DILocation(line: 11, column: 9, scope: !13)
!17 = !{!18, !18, i64 0}
!18 = !{!"int", !19, i64 0}
!19 = !{!"omnipotent char", !20, i64 0}
!20 = !{!"Simple C/C++ TBAA"}
!21 = !DILocation(line: 11, column: 6, scope: !13)
!22 = !DILocation(line: 12, column: 1, scope: !13)
!23 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 16, type: !24, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !29)
!24 = !DISubroutineType(types: !25)
!25 = !{!8, !8, !26}
!26 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !27, size: 64)
!27 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !28, size: 64)
!28 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!29 = !{!30, !31}
!30 = !DILocalVariable(name: "argc", arg: 1, scope: !23, file: !3, line: 16, type: !8)
!31 = !DILocalVariable(name: "argv", arg: 2, scope: !23, file: !3, line: 16, type: !26)
!32 = !DILocation(line: 0, scope: !23)
!33 = !DILocation(line: 17, column: 2, scope: !23)
!34 = !DILocation(line: 19, column: 9, scope: !23)
!35 = !{!36, !36, i64 0}
!36 = !{!"any pointer", !19, i64 0}
!37 = !DILocation(line: 19, column: 24, scope: !23)
!38 = !DILocation(line: 19, column: 22, scope: !23)
!39 = !{!19, !19, i64 0}
!40 = !DILocation(line: 19, column: 2, scope: !23)
