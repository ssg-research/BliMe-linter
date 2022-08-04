; ModuleID = '<stdin>'
source_filename = "example4.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"abc\00", align 1
@.str.1 = private unnamed_addr constant [12 x i8] c"Test case: \00", align 1
@str = private unnamed_addr constant [7 x i8] c"PASSED\00", align 1

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local signext i8 @case5(i8* nocapture readonly %arr, i8* blinded nocapture readonly %arr2, i32 %index) local_unnamed_addr #0 {
entry:
  %idxprom = sext i32 %index to i64
  %arrayidx = getelementptr inbounds i8, i8* %arr2, i64 %idxprom, !my.md.blindedPtr !2
  %0 = load i8, i8* %arrayidx, align 1, !tbaa !3, !my.md.blinded !6
  %idxprom1 = sext i8 %0 to i64, !my.md.blinded !6
  %arrayidx2 = getelementptr inbounds i8, i8* %arr, i64 %idxprom1, !my.md.blinded !6
  %1 = load i8, i8* %arrayidx2, align 1, !tbaa !3
  ret i8 %1
}

; Function Attrs: nofree noinline norecurse nounwind uwtable
define dso_local signext i8 @case6(i8* nocapture %arr, i8* blinded nocapture readonly %arr2, i32 %index, i32 %value) local_unnamed_addr #1 {
entry:
  %conv = trunc i32 %value to i8
  %idxprom = sext i32 %index to i64
  %arrayidx = getelementptr inbounds i8, i8* %arr2, i64 %idxprom, !my.md.blindedPtr !2
  %0 = load i8, i8* %arrayidx, align 1, !tbaa !3, !my.md.blinded !6
  %idxprom1 = sext i8 %0 to i64, !my.md.blinded !6
  %arrayidx2 = getelementptr inbounds i8, i8* %arr, i64 %idxprom1, !my.md.blinded !6
  store i8 %conv, i8* %arrayidx2, align 1, !tbaa !3
  ret i8 %conv
}

; Function Attrs: nofree noinline nounwind uwtable
define dso_local signext i8 @case8(i8* blinded nocapture %arr, i32 %index) local_unnamed_addr #2 {
entry:
  %idxprom = sext i32 %index to i64
  %arrayidx = getelementptr inbounds i8, i8* %arr, i64 %idxprom, !my.md.blindedPtr !2
  %0 = load i8, i8* %arrayidx, align 1, !tbaa !3, !my.md.blinded !6
  %cmp = icmp sgt i8 %0, 10, !my.md.blinded !6
  br i1 %cmp, label %if.then, label %if.else, !my.md.blinded !6

if.then:                                          ; preds = %entry
  store i8 7, i8* %arrayidx, align 1, !tbaa !3
  br label %if.end

if.else:                                          ; preds = %entry
  %call = call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0))
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  ret i8 undef
}

; Function Attrs: nofree nounwind
declare dso_local i32 @printf(i8* nocapture readonly, ...) local_unnamed_addr #3

; Function Attrs: nofree noinline nounwind uwtable
define dso_local signext i8 @case1(i8* blinded nocapture %arr, i32 %index) local_unnamed_addr #2 {
entry:
  %idxprom = sext i32 %index to i64
  %arrayidx = getelementptr inbounds i8, i8* %arr, i64 %idxprom, !my.md.blindedPtr !2
  %0 = load i8, i8* %arrayidx, align 1, !tbaa !3, !my.md.blinded !6
  %cmp = icmp sgt i8 %0, 10, !my.md.blinded !6
  br i1 %cmp, label %if.then, label %if.else, !my.md.blinded !6

if.then:                                          ; preds = %entry
  store i8 7, i8* %arrayidx, align 1, !tbaa !3
  br label %if.end

if.else:                                          ; preds = %entry
  %call = call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0))
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  ret i8 undef
}

; Function Attrs: nounwind uwtable
define dso_local i32 @main(i32 %argc, i8** nocapture readnone %argv) local_unnamed_addr #4 {
entry:
  %unblinded = alloca [1024 x i8], align 16
  %blinded = alloca [1024 x i8], align 16
  %0 = getelementptr inbounds [1024 x i8], [1024 x i8]* %unblinded, i64 0, i64 0
  call void @llvm.lifetime.start.p0i8(i64 1024, i8* nonnull %0) #8
  %1 = getelementptr inbounds [1024 x i8], [1024 x i8]* %blinded, i64 0, i64 0
  call void @llvm.lifetime.start.p0i8(i64 1024, i8* nonnull %1) #8
  %call = call i64 @read(i32 0, i8* nonnull %1, i64 1024) #8
  %call1 = call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([12 x i8], [12 x i8]* @.str.1, i64 0, i64 0))
  %call3 = call signext i8 @case1(i8* nonnull %1, i32 0)
  %call9 = call signext i8 @case6(i8* nonnull %1, i8* nonnull %0, i32 0, i32 10)
  %puts = call i32 @puts(i8* nonnull dereferenceable(1) getelementptr inbounds ([7 x i8], [7 x i8]* @str, i64 0, i64 0))
  call void @llvm.lifetime.end.p0i8(i64 1024, i8* nonnull %1) #8
  call void @llvm.lifetime.end.p0i8(i64 1024, i8* nonnull %0) #8
  ret i32 0
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #5

; Function Attrs: nofree
declare dso_local i64 @read(i32, i8* nocapture, i64) local_unnamed_addr #6

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #5

; Function Attrs: nofree nounwind
declare i32 @puts(i8* nocapture readonly) local_unnamed_addr #7

attributes #0 = { noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nofree noinline norecurse nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree noinline nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nofree nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { argmemonly nounwind willreturn }
attributes #6 = { nofree "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #7 = { nofree nounwind }
attributes #8 = { nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 11.0.0 (git@gitlab.com:ssg-research/platsec/attack-tolerant-execution/bc-llvm.git fb53b3eb37d72200acf9fac00d070ea0211eae35)"}
!2 = !{!"blindedPtrTag"}
!3 = !{!4, !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}
!6 = !{i64 1}
