; ModuleID = '<stdin>'
source_filename = "BlindedComputation/Transforms/markreturns-analysisupdate.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64"

@g_blinded = dso_local local_unnamed_addr global i32 0, align 4, !dbg !0 #0
@g_arr = dso_local local_unnamed_addr global [10 x i32] zeroinitializer, align 16, !dbg !6 #0

define dso_local void @doNothingCharPP(i8** nocapture %0) {
  ret void
}

define dso_local void @doNothingIntPP(i32** nocapture %0) {
  ret void
}

define dso_local void @doNothingCharP(i8* nocapture %0) {
  ret void
}

define dso_local void @doNothingIntP(i32* nocapture %0) {
  ret void
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_a1(i32 %i) local_unnamed_addr #1 !dbg !16 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !20, metadata !DIExpression()), !dbg !21
  %call = tail call i32 @gimme_blind_a2(i32 %i), !dbg !22, !my.md.blinded !23
  ret i32 %call, !dbg !24, !my.md.blinded !23
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_a2(i32 %i) local_unnamed_addr #1 !dbg !25 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !27, metadata !DIExpression()), !dbg !28
  %call = tail call i32 @gimme_blind_a3(i32 %i), !dbg !29, !my.md.blinded !23
  ret i32 %call, !dbg !30, !my.md.blinded !23
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_a3(i32 %i) local_unnamed_addr #1 !dbg !31 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !33, metadata !DIExpression()), !dbg !34
  %call = tail call i32 @gimme_blind_a4(i32 %i), !dbg !35, !my.md.blinded !23
  ret i32 %call, !dbg !36, !my.md.blinded !23
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_a4(i32 %i) local_unnamed_addr #1 !dbg !37 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !39, metadata !DIExpression()), !dbg !40
  %0 = load i32, i32* @g_blinded, align 4, !dbg !41, !tbaa !42, !my.md.blinded !23
  %add = add nsw i32 %0, %i, !dbg !46, !my.md.blinded !23
  ret i32 %add, !dbg !47, !my.md.blinded !23
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @need_blind_var(i32 %i) local_unnamed_addr #1 !dbg !48 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !50, metadata !DIExpression()), !dbg !51
  %idxprom = sext i32 %i to i64, !dbg !52
  %arrayidx = getelementptr inbounds [10 x i32], [10 x i32]* @g_arr, i64 0, i64 %idxprom, !dbg !52, !my.md.blindedPtr !53
  %0 = load i32, i32* %arrayidx, align 4, !dbg !52, !tbaa !42, !my.md.blinded !23
  ret i32 %0, !dbg !54, !my.md.blinded !23
}

; Function Attrs: blinded norecurse nounwind readonly uwtable
define dso_local i32 @simpleTest(i32 blinded %a) local_unnamed_addr #2 !dbg !55 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !57, metadata !DIExpression()), !dbg !58
  %call = tail call i32 @gimme_blind_a1(i32 1), !dbg !59
  %call1 = tail call i32 @need_blind_var(i32 %call), !dbg !60
  %call2 = tail call i32 @gimme_blind_b1(i32 2), !dbg !61, !my.md.blinded !23
  %call3 = tail call i32 @need_blind_var.1(i32 %call2), !dbg !62, !my.md.blinded !23
  %add = add nsw i32 %call3, %call1, !dbg !63, !my.md.blinded !23
  ret i32 %add, !dbg !64, !my.md.blinded !23
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_b1(i32 %i) local_unnamed_addr #1 !dbg !65 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !67, metadata !DIExpression()), !dbg !68
  %call = tail call i32 @gimme_blind_b2(i32 %i), !dbg !69, !my.md.blinded !23
  ret i32 %call, !dbg !70, !my.md.blinded !23
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_b2(i32 %i) local_unnamed_addr #1 !dbg !71 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !73, metadata !DIExpression()), !dbg !74
  %call = tail call i32 @gimme_blind_b3(i32 %i), !dbg !75, !my.md.blinded !23
  ret i32 %call, !dbg !76, !my.md.blinded !23
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_b3(i32 %i) local_unnamed_addr #1 !dbg !77 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !79, metadata !DIExpression()), !dbg !80
  %call = tail call i32 @gimme_blind_b4(i32 %i), !dbg !81, !my.md.blinded !23
  ret i32 %call, !dbg !82, !my.md.blinded !23
}

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @gimme_blind_b4(i32 %i) local_unnamed_addr #1 !dbg !83 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !85, metadata !DIExpression()), !dbg !86
  %0 = load i32, i32* @g_blinded, align 4, !dbg !87, !tbaa !42, !my.md.blinded !23
  %add = add nsw i32 %0, %i, !dbg !88, !my.md.blinded !23
  ret i32 %add, !dbg !89, !my.md.blinded !23
}

; Function Attrs: blinded norecurse nounwind readonly uwtable
define dso_local i32 @sanityCheck() local_unnamed_addr #2 !dbg !90 {
entry:
  %0 = load i32, i32* @g_blinded, align 4, !dbg !93, !tbaa !42, !my.md.blinded !23
  %call = tail call i32 @need_blind_var.1(i32 %0), !dbg !94, !my.md.blinded !23
  ret i32 %call, !dbg !95, !my.md.blinded !23
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

; Function Attrs: blinded noinline norecurse nounwind readonly uwtable
define dso_local i32 @need_blind_var.1(i32 blinded %i) local_unnamed_addr #1 !dbg !96 {
entry:
  call void @llvm.dbg.value(metadata i32 %i, metadata !98, metadata !DIExpression()), !dbg !99
  %idxprom = sext i32 %i to i64, !dbg !100, !my.md.blinded !23
  %0 = load i32, i32* getelementptr inbounds ([10 x i32], [10 x i32]* @g_arr, i64 0, i64 0), align 4
  br label %g_arr.loop.body

g_arr.loop.body:                                  ; preds = %g_arr.loop.body, %entry
  %g_arr.induc.var = phi i64 [ 0, %entry ], [ %8, %g_arr.loop.body ]
  %g_arr.cur.element = phi i32 [ %0, %entry ], [ %7, %g_arr.loop.body ], !my.md.blinded !23
  %g_arr.blinded.addr = getelementptr [10 x i32], [10 x i32]* @g_arr, i64 0, i64 %g_arr.induc.var
  %1 = load i32, i32* %g_arr.blinded.addr, align 4
  %2 = icmp eq i64 %g_arr.induc.var, %idxprom, !my.md.blinded !23
  %3 = sub i1 false, %2
  %4 = sext i1 %3 to i32
  %5 = xor i32 %1, %g_arr.cur.element
  %6 = and i32 %4, %5
  %7 = xor i32 %6, %g_arr.cur.element
  %8 = add nsw i64 %g_arr.induc.var, 1
  %9 = icmp slt i64 %g_arr.induc.var, 10
  br i1 %9, label %g_arr.loop.body, label %g_arr.after.loop

g_arr.after.loop:                                 ; preds = %g_arr.loop.body
  ret i32 %7, !dbg !101, !my.md.blinded !23
}

attributes #0 = { blinded }
attributes #1 = { blinded noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { blinded norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind readnone speculatable willreturn }

!llvm.dbg.cu = !{!2}
!llvm.module.flags = !{!12, !13, !14}
!llvm.ident = !{!15}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "g_blinded", scope: !2, file: !3, line: 18, type: !9, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, producer: "clang version 11.0", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !4, globals: !5, splitDebugInlining: false, nameTableKind: None)
!3 = !DIFile(filename: "BlindedComputation/Transforms/markreturns-analysisupdate.c", directory: "")
!4 = !{}
!5 = !{!0, !6}
!6 = !DIGlobalVariableExpression(var: !7, expr: !DIExpression())
!7 = distinct !DIGlobalVariable(name: "g_arr", scope: !2, file: !3, line: 17, type: !8, isLocal: false, isDefinition: true)
!8 = !DICompositeType(tag: DW_TAG_array_type, baseType: !9, size: 320, elements: !10)
!9 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!10 = !{!11}
!11 = !DISubrange(count: 10)
!12 = !{i32 7, !"Dwarf Version", i32 4}
!13 = !{i32 2, !"Debug Info Version", i32 3}
!14 = !{i32 1, !"wchar_size", i32 4}
!15 = !{!"clang version 11.0.0"}
!16 = distinct !DISubprogram(name: "gimme_blind_a1", scope: !3, file: !3, line: 29, type: !17, scopeLine: 29, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !19)
!17 = !DISubroutineType(types: !18)
!18 = !{!9, !9}
!19 = !{!20}
!20 = !DILocalVariable(name: "i", arg: 1, scope: !16, file: !3, line: 29, type: !9)
!21 = !DILocation(line: 0, scope: !16)
!22 = !DILocation(line: 29, column: 36, scope: !16)
!23 = !{i64 1}
!24 = !DILocation(line: 29, column: 29, scope: !16)
!25 = distinct !DISubprogram(name: "gimme_blind_a2", scope: !3, file: !3, line: 30, type: !17, scopeLine: 30, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !26)
!26 = !{!27}
!27 = !DILocalVariable(name: "i", arg: 1, scope: !25, file: !3, line: 30, type: !9)
!28 = !DILocation(line: 0, scope: !25)
!29 = !DILocation(line: 30, column: 36, scope: !25)
!30 = !DILocation(line: 30, column: 29, scope: !25)
!31 = distinct !DISubprogram(name: "gimme_blind_a3", scope: !3, file: !3, line: 31, type: !17, scopeLine: 31, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !32)
!32 = !{!33}
!33 = !DILocalVariable(name: "i", arg: 1, scope: !31, file: !3, line: 31, type: !9)
!34 = !DILocation(line: 0, scope: !31)
!35 = !DILocation(line: 31, column: 36, scope: !31)
!36 = !DILocation(line: 31, column: 29, scope: !31)
!37 = distinct !DISubprogram(name: "gimme_blind_a4", scope: !3, file: !3, line: 32, type: !17, scopeLine: 32, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !38)
!38 = !{!39}
!39 = !DILocalVariable(name: "i", arg: 1, scope: !37, file: !3, line: 32, type: !9)
!40 = !DILocation(line: 0, scope: !37)
!41 = !DILocation(line: 32, column: 36, scope: !37)
!42 = !{!43, !43, i64 0}
!43 = !{!"int", !44, i64 0}
!44 = !{!"omnipotent char", !45, i64 0}
!45 = !{!"Simple C/C++ TBAA"}
!46 = !DILocation(line: 32, column: 46, scope: !37)
!47 = !DILocation(line: 32, column: 29, scope: !37)
!48 = distinct !DISubprogram(name: "need_blind_var", scope: !3, file: !3, line: 35, type: !17, scopeLine: 35, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !49)
!49 = !{!50}
!50 = !DILocalVariable(name: "i", arg: 1, scope: !48, file: !3, line: 35, type: !9)
!51 = !DILocation(line: 0, scope: !48)
!52 = !DILocation(line: 36, column: 10, scope: !48)
!53 = !{!"blindedPtrTag"}
!54 = !DILocation(line: 36, column: 3, scope: !48)
!55 = distinct !DISubprogram(name: "simpleTest", scope: !3, file: !3, line: 47, type: !17, scopeLine: 47, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !56)
!56 = !{!57}
!57 = !DILocalVariable(name: "a", arg: 1, scope: !55, file: !3, line: 47, type: !9)
!58 = !DILocation(line: 0, scope: !55)
!59 = !DILocation(line: 48, column: 25, scope: !55)
!60 = !DILocation(line: 48, column: 10, scope: !55)
!61 = !DILocation(line: 48, column: 61, scope: !55)
!62 = !DILocation(line: 48, column: 46, scope: !55)
!63 = !DILocation(line: 48, column: 44, scope: !55)
!64 = !DILocation(line: 48, column: 3, scope: !55)
!65 = distinct !DISubprogram(name: "gimme_blind_b1", scope: !3, file: !3, line: 51, type: !17, scopeLine: 51, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !66)
!66 = !{!67}
!67 = !DILocalVariable(name: "i", arg: 1, scope: !65, file: !3, line: 51, type: !9)
!68 = !DILocation(line: 0, scope: !65)
!69 = !DILocation(line: 51, column: 36, scope: !65)
!70 = !DILocation(line: 51, column: 29, scope: !65)
!71 = distinct !DISubprogram(name: "gimme_blind_b2", scope: !3, file: !3, line: 52, type: !17, scopeLine: 52, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !72)
!72 = !{!73}
!73 = !DILocalVariable(name: "i", arg: 1, scope: !71, file: !3, line: 52, type: !9)
!74 = !DILocation(line: 0, scope: !71)
!75 = !DILocation(line: 52, column: 36, scope: !71)
!76 = !DILocation(line: 52, column: 29, scope: !71)
!77 = distinct !DISubprogram(name: "gimme_blind_b3", scope: !3, file: !3, line: 53, type: !17, scopeLine: 53, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !78)
!78 = !{!79}
!79 = !DILocalVariable(name: "i", arg: 1, scope: !77, file: !3, line: 53, type: !9)
!80 = !DILocation(line: 0, scope: !77)
!81 = !DILocation(line: 53, column: 36, scope: !77)
!82 = !DILocation(line: 53, column: 29, scope: !77)
!83 = distinct !DISubprogram(name: "gimme_blind_b4", scope: !3, file: !3, line: 54, type: !17, scopeLine: 54, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !84)
!84 = !{!85}
!85 = !DILocalVariable(name: "i", arg: 1, scope: !83, file: !3, line: 54, type: !9)
!86 = !DILocation(line: 0, scope: !83)
!87 = !DILocation(line: 54, column: 36, scope: !83)
!88 = !DILocation(line: 54, column: 46, scope: !83)
!89 = !DILocation(line: 54, column: 29, scope: !83)
!90 = distinct !DISubprogram(name: "sanityCheck", scope: !3, file: !3, line: 61, type: !91, scopeLine: 61, flags: DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !4)
!91 = !DISubroutineType(types: !92)
!92 = !{!9}
!93 = !DILocation(line: 62, column: 25, scope: !90)
!94 = !DILocation(line: 62, column: 10, scope: !90)
!95 = !DILocation(line: 62, column: 3, scope: !90)
!96 = distinct !DISubprogram(name: "need_blind_var", scope: !3, file: !3, line: 35, type: !17, scopeLine: 35, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !97)
!97 = !{!98}
!98 = !DILocalVariable(name: "i", arg: 1, scope: !96, file: !3, line: 35, type: !9)
!99 = !DILocation(line: 0, scope: !96)
!100 = !DILocation(line: 36, column: 10, scope: !96)
!101 = !DILocation(line: 36, column: 3, scope: !96)
