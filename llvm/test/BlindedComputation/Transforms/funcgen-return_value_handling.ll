; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s -check-prefix=NEWFUNC
; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s -check-prefix=RETURNS
; 
; THIS IS A GENERATED TEST, DO NOT MODIFY HERE!!!
; Instead, modify it under /bc/llvm-test and install from there!
; 

; CFLAGS: --target=x86_64  -Wall -O2 -Xclang -disable-lifetime-markers  -fno-discard-value-names  -fno-unroll-loops -gdwarf

; 
; int arr[100];
; 
; __attribute__((blinded)) int blind_sink = 0;
; int plain_sink = 0;
; 
; We expect to have 1 new variants of this function, such that it has both
; blinded inputs and outputs. We also expect that the original function
; remains as is, without any blinded in-/out-puts.
; 
; NEWFUNC: define {{.*}} @addOne({{.*}}[[ATTRIBUTE_PLAIN:#[0-9]+]] {{( *![a-z0-9]+)*}} {
; NEWFUNC: define {{.*}} @addOne{{\.[a-z0-9]+}}({{.*}}[[ATTRIBUTE_BLINDED:#[0-9]+]] {{( *![a-z0-9]+)*}} {
; NEWFUNC-NOT: attributes [[ATTRIBUTE_PLAIN]]{{.*}}blinded
; NEWFUNC: attributes [[ATTRIBUTE_BLINDED]]{{.*}}blinded
; //
; __attribute__((noinline))
; int addOne(int i) {
; 	return i + 1;
; }
; 
; We expect this function to be marked blinded because one of the addOne calls
; should be converted to a blinded function and hence cause this to return a
; blinded value also.
; 
; RETURNS: @do_stuff{{.*}}[[ATTRIBUTE_BLINDED:#[0-9]+]] {{( *![a-z0-9]+)*}} {
; RETURNS: attributes [[ATTRIBUTE_BLINDED]]{{.*}}blinded
; __attribute__((noinline))
; int do_stuff(__attribute__((blinded)) int blinded, int plain) {
;   // Expect addOne(blinded) to have blinded return value, consequently we also
;   // expect this function to be converted to a blinded version.
;   return addOne(blinded) + addOne(plain);
; }
; 
; int main() {
; 	do_stuff(1, 1);
;   return 0;
; }



; ModuleID = 'BlindedComputation/Transforms/funcgen-return_value_handling.c'
source_filename = "BlindedComputation/Transforms/funcgen-return_value_handling.c"
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

; Function Attrs: norecurse nounwind readnone uwtable
define dso_local i32 @main() local_unnamed_addr #2 !dbg !37 {
entry:
  ret i32 0, !dbg !40
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { blinded }
attributes #1 = { noinline norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { norecurse nounwind readnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!14, !15, !16}
!llvm.ident = !{!17}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "blind_sink", scope: !2, file: !3, line: 6, type: !8, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/funcgen-return_value_handling.c", directory: "/home/ishkamiel/d/llvm/bc/llvm-test")
!4 = !{}
!5 = !{!0, !6, !9}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "plain_sink", scope: !2, file: !3, line: 7, type: !8, isLocal: false, isDefinition: true)
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!9 = !DIGlobalVariableExpression(var: !10, expr: !DIExpression())
!10 = distinct !DIGlobalVariable(name: "arr", scope: !2, file: !3, line: 4, type: !11, isLocal: false, isDefinition: true)
!11 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 3200, elements: !12)
!12 = !{!13}
!13 = !DISubrange(count: 100)
!14 = !{i32 7, !"Dwarf Version", i32 4}
!15 = !{i32 2, !"Debug Info Version", i32 3}
!16 = !{i32 1, !"wchar_size", i32 4}
!17 = !{!"clang version 11.0.0"}
!18 = distinct !DISubprogram(name: "addOne", scope: !3, file: !3, line: 19, type: !19, scopeLine: 19, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !21)
!19 = !DISubroutineType(types: !20)
!20 = !{!8, !8}
!21 = !{!22}
!22 = !DILocalVariable(name: "i", arg: 1, scope: !18, file: !3, line: 19, type: !8)
!23 = !DILocation(line: 0, scope: !18)
!24 = !DILocation(line: 20, column: 11, scope: !18)
!25 = !DILocation(line: 20, column: 2, scope: !18)
!26 = distinct !DISubprogram(name: "do_stuff", scope: !3, file: !3, line: 30, type: !27, scopeLine: 30, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !29)
!27 = !DISubroutineType(types: !28)
!28 = !{!8, !8, !8}
!29 = !{!30, !31}
!30 = !DILocalVariable(name: "blinded", arg: 1, scope: !26, file: !3, line: 30, type: !8)
!31 = !DILocalVariable(name: "plain", arg: 2, scope: !26, file: !3, line: 30, type: !8)
!32 = !DILocation(line: 0, scope: !26)
!33 = !DILocation(line: 33, column: 10, scope: !26)
!34 = !DILocation(line: 33, column: 28, scope: !26)
!35 = !DILocation(line: 33, column: 26, scope: !26)
!36 = !DILocation(line: 33, column: 3, scope: !26)
!37 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 36, type: !38, scopeLine: 36, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!38 = !DISubroutineType(types: !39)
!39 = !{!8}
!40 = !DILocation(line: 38, column: 3, scope: !37)
