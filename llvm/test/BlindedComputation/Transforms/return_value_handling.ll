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
; int plain_sink = 0;
; 
; __attribute__((noinline))
; int addOne(int i) {
; 	return i + 1;
; }
; 
; __attribute__((noinline))
; int do_stuff(__attribute__((blinded)) int blinded, int plain) {
;   return addOne(blinded) + addOne(plain);
; }
; 
; int main(int argc, char **argv) {
; 	do_stuff(1, 1);
;   return argv[0][do_stuff(1, 1)];
; }



; ModuleID = 'BlindedComputation/Transforms/return_value_handling.c'
source_filename = "BlindedComputation/Transforms/return_value_handling.c"
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
@plain_sink = dso_local local_unnamed_addr global i32 0, align 4, !dbg !6
@arr = dso_local local_unnamed_addr global [100 x i32] zeroinitializer, align 16, !dbg !9

; Function Attrs: noinline norecurse nounwind readnone uwtable
define dso_local i32 @addOne(i32 %i) local_unnamed_addr #1 !dbg !18 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !22, metadata !DIExpression()), !dbg !23
  %add = add nsw i32 %i, 1, !dbg !24
  ret i32 %add, !dbg !25
}

; Function Attrs: noinline norecurse nounwind readnone uwtable
define dso_local i32 @do_stuff(i32 blinded %blinded, i32 %plain) local_unnamed_addr #1 !dbg !26 {
entry:
  call void @llvm.dbg.value(metadata i32 %blinded, metadata !30, metadata !DIExpression()), !dbg !32
  call void @llvm.dbg.value(metadata i32 %plain, metadata !31, metadata !DIExpression()), !dbg !32
  %call = tail call i32 @addOne(i32 %blinded), !dbg !33
  %call1 = tail call i32 @addOne(i32 %plain), !dbg !34
  %add = add nsw i32 %call1, %call, !dbg !35
  ret i32 %add, !dbg !36
}

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @main(i32 %argc, i8** nocapture readonly %argv) local_unnamed_addr #2 !dbg !37 {
entry:
  call void @llvm.dbg.value(metadata i32 %argc, metadata !44, metadata !DIExpression()), !dbg !46
  call void @llvm.dbg.value(metadata i8** %argv, metadata !45, metadata !DIExpression()), !dbg !46
  %0 = load i8*, i8** %argv, align 8, !dbg !47, !tbaa !48
  %call1 = tail call i32 @do_stuff(i32 1, i32 1), !dbg !52
  %idxprom = sext i32 %call1 to i64, !dbg !47
  %arrayidx2 = getelementptr inbounds i8, i8* %0, i64 %idxprom, !dbg !47
  %1 = load i8, i8* %arrayidx2, align 1, !dbg !47, !tbaa !53
  %conv = sext i8 %1 to i32, !dbg !47
  ret i32 %conv, !dbg !54
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { blinded }
attributes #1 = { noinline norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!14, !15, !16}
!llvm.ident = !{!17}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "blind_sink", scope: !2, file: !3, line: 5, type: !8, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/return_value_handling.c", directory: "")
!4 = !{}
!5 = !{!0, !6, !9}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "plain_sink", scope: !2, file: !3, line: 6, type: !8, isLocal: false, isDefinition: true)
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 3, type: !11, isLocal: false, isDefinition: true)
!11 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 3200, elements: !12)
!12 = !{!13}
!13 = !DISubrange(count: 100)
!14 = !{i32 7, !"Dwarf Version", i32 4}
!15 = !{i32 2, !"Debug Info Version", i32 3}
!16 = !{i32 1, !"wchar_size", i32 4}
!17 = !{!"clang version 11.0.0"}
!18 = distinct !DISubprogram(name: "addOne", scope: !3, file: !3, line: 9, type: !19, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !21)
!19 = !DISubroutineType(types: !20)
!20 = !{!8, !8}
!21 = !{!22}
!22 = !DILocalVariable(name: "i", arg: 1, scope: !18, file: !3, line: 9, type: !8)
!23 = !DILocation(line: 0, scope: !18)
!24 = !DILocation(line: 10, column: 11, scope: !18)
!25 = !DILocation(line: 10, column: 2, scope: !18)
!26 = distinct !DISubprogram(name: "do_stuff", scope: !3, file: !3, line: 14, type: !27, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !29)
!27 = !DISubroutineType(types: !28)
!28 = !{!8, !8, !8}
!29 = !{!30, !31}
!30 = !DILocalVariable(name: "blinded", arg: 1, scope: !26, file: !3, line: 14, type: !8)
!31 = !DILocalVariable(name: "plain", arg: 2, scope: !26, file: !3, line: 14, type: !8)
!32 = !DILocation(line: 0, scope: !26)
!33 = !DILocation(line: 15, column: 10, scope: !26)
!34 = !DILocation(line: 15, column: 28, scope: !26)
!35 = !DILocation(line: 15, column: 26, scope: !26)
!36 = !DILocation(line: 15, column: 3, scope: !26)
!37 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 18, type: !38, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !43)
!38 = !DISubroutineType(types: !39)
!39 = !{!8, !8, !40}
!40 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !41, size: 64)
!41 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !42, size: 64)
!42 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!43 = !{!44, !45}
!44 = !DILocalVariable(name: "argc", arg: 1, scope: !37, file: !3, line: 18, type: !8)
!45 = !DILocalVariable(name: "argv", arg: 2, scope: !37, file: !3, line: 18, type: !40)
!46 = !DILocation(line: 0, scope: !37)
!47 = !DILocation(line: 20, column: 10, scope: !37)
!48 = !{!49, !49, i64 0}
!49 = !{!"any pointer", !50, i64 0}
!50 = !{!"omnipotent char", !51, i64 0}
!51 = !{!"Simple C/C++ TBAA"}
!52 = !DILocation(line: 20, column: 18, scope: !37)
!53 = !{!50, !50, i64 0}
!54 = !DILocation(line: 20, column: 3, scope: !37)
