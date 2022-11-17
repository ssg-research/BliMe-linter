; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

@scale = dso_local global i32 3, align 4
@offset = dso_local global i32 12, align 4
@arr = dso_local global [100 x i8] zeroinitializer, align 16

; CHECK-LABEL: @accessArray(
; CHECK-NOT:     getelementptr inbounds [100 x i8], [100 x i8]* @arr, i64 0, i64 {{%.*}}
; COM: CHECK:         getelementptr inbounds ([100 x i8], [100 x i8]* @arr, i64 0, i64 0), align 1
; CHECK:    br label {{%.*}}
; Disable the follwoing since they're incompatible with the select transforms
; DIABLE-CHECK:         [[RET:%.*]] = select i1 {{%.*}}, i8 {{%.*}}, i8 {{%.*}}
; DIABLE-CHECK:         ret i8 [[RET]]

; Function Attrs: noinline nounwind optnone uwtable
define dso_local signext i8 @accessArray(i32 blinded %index) #0 {
entry:
  %index.addr = alloca i32, align 4
  %targetIndex = alloca i32, align 4
  %pTargetIdx = alloca i32*, align 8
  store i32 %index, i32* %index.addr, align 4
  %0 = load i32, i32* %index.addr, align 4
  %1 = load i32, i32* @scale, align 4
  %mul = mul nsw i32 %0, %1
  store i32 %mul, i32* %targetIndex, align 4
  store i32* %targetIndex, i32** %pTargetIdx, align 8
  %2 = load i32*, i32** %pTargetIdx, align 8
  %3 = load i32, i32* %2, align 4
  %4 = load i32, i32* @offset, align 4
  %add = add nsw i32 %3, %4
  %idxprom = sext i32 %add to i64
  %arrayidx = getelementptr inbounds [100 x i8], [100 x i8]* @arr, i64 0, i64 %idxprom
  %5 = load i8, i8* %arrayidx, align 1
  ret i8 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  store i32 0, i32* %retval, align 4
  %call = call signext i8 @accessArray(i32 5)
  ret i32 0
}
