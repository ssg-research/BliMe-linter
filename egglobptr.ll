; ModuleID = '<stdin>'
source_filename = "globalptrexample.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@a = dso_local global i32 1, align 4 #0
@b = dso_local local_unnamed_addr global i32* @a, align 8
@__const.arrayMess2.arr = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local i32 @arrayMess2() local_unnamed_addr #1 {
entry:
  %0 = load i32*, i32** @b, align 8, !tbaa !2
  %1 = load i32, i32* %0, align 4, !tbaa !6
  %idxprom = sext i32 %1 to i64
  %arrayidx = getelementptr inbounds [4 x i32], [4 x i32]* @__const.arrayMess2.arr, i64 0, i64 %idxprom
  %2 = load i32, i32* %arrayidx, align 4, !tbaa !6
  ret i32 %2
}

attributes #0 = { blinded }
attributes #1 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 11.0.0 (git@gitlab.com:ssg-research/platsec/attack-tolerant-execution/bc-llvm.git fb53b3eb37d72200acf9fac00d070ea0211eae35)"}
!2 = !{!3, !3, i64 0}
!3 = !{!"any pointer", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !4, i64 0}
