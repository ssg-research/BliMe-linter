; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -I/usr/include/x86_64-linux-gnu -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; 
; int arr[100];
; 
; __attribute__((blinded)) int blind_sink = 0;
; 
; __attribute__((noinline))
; int addOne(int i) {
; 	return i + 1;
; }
; 
; __attribute__((noinline))
; int do_stuff(int i) {
;   return blind_sink + i;
; }
; 
; CHECK: stuff...
; int main(int argc, char **argv) {
;   return argv[0][do_stuff(1)];
; }



; ModuleID = 'BlindedComputation/Transforms/return_value_handling_1.c'
source_filename = "BlindedComputation/Transforms/return_value_handling_1.c"
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

@blind_sink = dso_local local_unnamed_addr global i32 0, align 4, !dbg !0 #0
@arr = dso_local local_unnamed_addr global [100 x i32] zeroinitializer, align 16, !dbg !6

; Function Attrs: noinline norecurse nounwind readnone uwtable
define dso_local i32 @addOne(i32 %i) local_unnamed_addr #1 !dbg !16 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !20, metadata !DIExpression()), !dbg !21
  %add = add nsw i32 %i, 1, !dbg !22
  ret i32 %add, !dbg !23
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local i32 @do_stuff(i32 %i) local_unnamed_addr #2 !dbg !24 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !26, metadata !DIExpression()), !dbg !27
  %0 = load i32, i32* @blind_sink, align 4, !dbg !28, !tbaa !29
  %add = add nsw i32 %0, %i, !dbg !33
  ret i32 %add, !dbg !34
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @main(i32 %argc, i8** nocapture readonly %argv) local_unnamed_addr #3 !dbg !35 {
entry:
  call void @llvm.dbg.value(metadata i32 %argc, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i8** %argv, metadata !43, metadata !DIExpression()), !dbg !44
  %0 = load i8*, i8** %argv, align 8, !dbg !45, !tbaa !46
  %call = tail call i32 @do_stuff(i32 1), !dbg !48
  %idxprom = sext i32 %call to i64, !dbg !45
  %arrayidx1 = getelementptr inbounds i8, i8* %0, i64 %idxprom, !dbg !45
  %1 = load i8, i8* %arrayidx1, align 1, !dbg !45, !tbaa !49
  %conv = sext i8 %1 to i32, !dbg !45
  ret i32 %conv, !dbg !50
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #4

attributes #0 = { blinded }
attributes #1 = { noinline norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!12, !13, !14}
!llvm.ident = !{!15}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "blind_sink", scope: !2, file: !3, line: 5, type: !9, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/return_value_handling_1.c", directory: "")
!4 = !{}
!5 = !{!0, !6}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 3, type: !8, isLocal: false, isDefinition: true)
!8 = !DICompositeType(tag: DW_TAG_array_type, baseType: !9, size: 3200, elements: !10)
!9 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!10 = !{!11}
!11 = !DISubrange(count: 100)
!12 = !{i32 7, !"Dwarf Version", i32 4}
!13 = !{i32 2, !"Debug Info Version", i32 3}
!14 = !{i32 1, !"wchar_size", i32 4}
!15 = !{!"clang version 11.0.0"}
!16 = distinct !DISubprogram(name: "addOne", scope: !3, file: !3, line: 8, type: !17, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !19)
!17 = !DISubroutineType(types: !18)
!18 = !{!9, !9}
!19 = !{!20}
!20 = !DILocalVariable(name: "i", arg: 1, scope: !16, file: !3, line: 8, type: !9)
!21 = !DILocation(line: 0, scope: !16)
!22 = !DILocation(line: 9, column: 11, scope: !16)
!23 = !DILocation(line: 9, column: 2, scope: !16)
!24 = distinct !DISubprogram(name: "do_stuff", scope: !3, file: !3, line: 13, type: !17, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !25)
!25 = !{!26}
!26 = !DILocalVariable(name: "i", arg: 1, scope: !24, file: !3, line: 13, type: !9)
!27 = !DILocation(line: 0, scope: !24)
!28 = !DILocation(line: 14, column: 10, scope: !24)
!29 = !{!30, !30, i64 0}
!30 = !{!"int", !31, i64 0}
!31 = !{!"omnipotent char", !32, i64 0}
!32 = !{!"Simple C/C++ TBAA"}
!33 = !DILocation(line: 14, column: 21, scope: !24)
!34 = !DILocation(line: 14, column: 3, scope: !24)
!35 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 18, type: !36, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !41)
!36 = !DISubroutineType(types: !37)
!37 = !{!9, !9, !38}
!38 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !39, size: 64)
!39 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!40 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!41 = !{!42, !43}
!42 = !DILocalVariable(name: "argc", arg: 1, scope: !35, file: !3, line: 18, type: !9)
!43 = !DILocalVariable(name: "argv", arg: 2, scope: !35, file: !3, line: 18, type: !38)
!44 = !DILocation(line: 0, scope: !35)
!45 = !DILocation(line: 19, column: 10, scope: !35)
!46 = !{!47, !47, i64 0}
!47 = !{!"any pointer", !31, i64 0}
!48 = !DILocation(line: 19, column: 18, scope: !35)
!49 = !{!31, !31, i64 0}
!50 = !DILocation(line: 19, column: 3, scope: !35)
