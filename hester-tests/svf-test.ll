; ModuleID = 'svf-test.c'
source_filename = "svf-test.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [7 x i8] c"%d%d%d\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @add_nums(i32 %a, i32 %b) #0 {
entry:
  %a.addr = alloca i32, align 4
  %b.addr = alloca i32, align 4
  %d = alloca i32, align 4
  store i32 %a, i32* %a.addr, align 4
  store i32 %b, i32* %b.addr, align 4
  store i32 18, i32* %d, align 4
  %0 = load i32, i32* %a.addr, align 4
  %1 = load i32, i32* %d, align 4
  %add = add nsw i32 %0, %1
  ret i32 %add
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @test_alias(i32 %a, i32 %b) #0 {
entry:
  %a.addr = alloca i32, align 4
  %b.addr = alloca i32, align 4
  %c = alloca i32*, align 8
  %d = alloca i32*, align 8
  store i32 %a, i32* %a.addr, align 4
  store i32 %b, i32* %b.addr, align 4
  store i32* %a.addr, i32** %c, align 8
  %0 = load i32*, i32** %c, align 8
  store i32* %0, i32** %d, align 8
  %1 = load i32, i32* %b.addr, align 4
  %2 = load i32*, i32** %c, align 8
  store i32 %1, i32* %2, align 4
  %3 = load i32*, i32** %d, align 8
  %4 = load i32, i32* %3, align 4
  ret i32 %4
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @test_cond(i32 %cond, i32 %idx) #0 {
entry:
  %cond.addr = alloca i32, align 4
  %idx.addr = alloca i32, align 4
  %arr = alloca [12 x i32], align 16
  %arr2 = alloca [12 x i32], align 16
  %i = alloca i32, align 4
  store i32 %cond, i32* %cond.addr, align 4
  store i32 %idx, i32* %idx.addr, align 4
  %0 = bitcast [12 x i32]* %arr to i8*
  call void @llvm.memset.p0i8.i64(i8* align 16 %0, i8 0, i64 48, i1 false)
  %1 = bitcast i8* %0 to <{ i32, i32, i32, [9 x i32] }>*
  %2 = getelementptr inbounds <{ i32, i32, i32, [9 x i32] }>, <{ i32, i32, i32, [9 x i32] }>* %1, i32 0, i32 0
  store i32 1, i32* %2, align 16
  %3 = getelementptr inbounds <{ i32, i32, i32, [9 x i32] }>, <{ i32, i32, i32, [9 x i32] }>* %1, i32 0, i32 1
  store i32 2, i32* %3, align 4
  %4 = getelementptr inbounds <{ i32, i32, i32, [9 x i32] }>, <{ i32, i32, i32, [9 x i32] }>* %1, i32 0, i32 2
  store i32 3, i32* %4, align 8
  %5 = bitcast [12 x i32]* %arr2 to i8*
  call void @llvm.memset.p0i8.i64(i8* align 16 %5, i8 0, i64 48, i1 false)
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %6 = load i32, i32* %i, align 4
  %cmp = icmp slt i32 %6, 10
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %7 = load i32, i32* %idx.addr, align 4
  %8 = load i32, i32* %i, align 4
  %idxprom = sext i32 %8 to i64
  %arrayidx = getelementptr inbounds [12 x i32], [12 x i32]* %arr, i64 0, i64 %idxprom
  %9 = load i32, i32* %arrayidx, align 4
  %add = add nsw i32 %9, %7
  store i32 %add, i32* %arrayidx, align 4
  %10 = load i32, i32* %cond.addr, align 4
  %11 = load i32, i32* %i, align 4
  %idxprom1 = sext i32 %11 to i64
  %arrayidx2 = getelementptr inbounds [12 x i32], [12 x i32]* %arr2, i64 0, i64 %idxprom1
  %12 = load i32, i32* %arrayidx2, align 4
  %sub = sub nsw i32 %12, %10
  store i32 %sub, i32* %arrayidx2, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %13 = load i32, i32* %i, align 4
  %inc = add nsw i32 %13, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  %14 = load i32, i32* %cond.addr, align 4
  %cmp3 = icmp sgt i32 %14, 5
  br i1 %cmp3, label %cond.true, label %cond.false

cond.true:                                        ; preds = %for.end
  %arraydecay = getelementptr inbounds [12 x i32], [12 x i32]* %arr, i64 0, i64 0
  br label %cond.end

cond.false:                                       ; preds = %for.end
  %arraydecay4 = getelementptr inbounds [12 x i32], [12 x i32]* %arr2, i64 0, i64 0
  br label %cond.end

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond5 = phi i32* [ %arraydecay, %cond.true ], [ %arraydecay4, %cond.false ]
  %15 = load i32, i32* %idx.addr, align 4
  %idxprom6 = sext i32 %15 to i64
  %arrayidx7 = getelementptr inbounds i32, i32* %cond5, i64 %idxprom6
  %16 = load i32, i32* %arrayidx7, align 4
  ret i32 %16
}

; Function Attrs: argmemonly nounwind willreturn writeonly
declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i1 immarg) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %a = alloca i32, align 4
  %b = alloca i32, align 4
  %q1 = alloca i32*, align 8
  %q2 = alloca i32**, align 8
  %q3 = alloca i32***, align 8
  %c = alloca i32, align 4
  %d = alloca i32, align 4
  %e = alloca i32, align 4
  store i32 0, i32* %retval, align 4
  store i32 10, i32* %a, align 4
  store i32 15, i32* %b, align 4
  store i32* %a, i32** %q1, align 8
  store i32** %q1, i32*** %q2, align 8
  store i32*** %q2, i32**** %q3, align 8
  %0 = load i32, i32* %a, align 4
  %1 = load i32, i32* %b, align 4
  %call = call i32 @add_nums(i32 %0, i32 %1)
  store i32 %call, i32* %c, align 4
  %2 = load i32, i32* %a, align 4
  %3 = load i32, i32* %b, align 4
  %call1 = call i32 @test_alias(i32 %2, i32 %3)
  store i32 %call1, i32* %d, align 4
  %4 = load i32, i32* %b, align 4
  %5 = load i32, i32* %a, align 4
  %call2 = call i32 @test_cond(i32 %4, i32 %5)
  store i32 %call2, i32* %e, align 4
  %6 = load i32, i32* %c, align 4
  %7 = load i32, i32* %d, align 4
  %8 = load i32, i32* %e, align 4
  %call3 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str, i64 0, i64 0), i32 %6, i32 %7, i32 %8)
  ret i32 0
}

declare dso_local i32 @printf(i8*, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind willreturn writeonly }
attributes #2 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 11.0.0 (git@gitlab.com:ssg-research/platsec/attack-tolerant-execution/bc-llvm.git d6d3d1745f398f9133df6dc48a62b836ba8e4446)"}
