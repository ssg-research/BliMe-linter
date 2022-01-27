; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
; XFAIL: *

; This test fails due to inaccurate taint analysis. 
; In accessArray, in %1, we load from a "pointer to pointer to blinded data" 
; but see the result as blinded data rather than pointer to blinded data.
; As a result, in %2 sentence, BlindedDataUsage.cpp determines that we are
; using blinded data as pointer to load, which is a violation to the policy.
; Remove XFAIL when better taint analysis get implemented and try if it's fixed.

@key = dso_local global i32 2, align 4 #0
@pKey = dso_local global i32* @key, align 8
@arr = dso_local global [100 x i32] zeroinitializer, align 16

; CHECK-LABEL: @accessArray(
; CHECK-NOT:     getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 {{%.*}}
; CHECK:         getelementptr inbounds ([100 x i32], [100 x i32]* @arr, i64 0, i64 0), align 4
; CHECK-NEXT:    br label {{%.*}}
; Disable the follwoing since they're incompatible with the select transforms
; DIABLE-CHECK:         [[RET:%.*]] = select i1 {{%.*}}, i32 {{%.*}}, i32 {{%.*}}
; DIABLE-CHECK:         ret i32 [[RET]]

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @accessArray(i32 %scale, i32 %offset) #1 {
entry:
  %scale.addr = alloca i32, align 4
  %offset.addr = alloca i32, align 4
  %computedKey = alloca i32, align 4
  %pComputedKey = alloca i32*, align 8
  store i32 %scale, i32* %scale.addr, align 4
  store i32 %offset, i32* %offset.addr, align 4
  %0 = load i32, i32* %scale.addr, align 4
  %1 = load i32*, i32** @pKey, align 8
  %2 = load i32, i32* %1, align 4
  %mul = mul nsw i32 %0, %2
  %3 = load i32, i32* %offset.addr, align 4
  %add = add nsw i32 %mul, %3
  store i32 %add, i32* %computedKey, align 4
  store i32* %computedKey, i32** %pComputedKey, align 8
  %4 = load i32*, i32** %pComputedKey, align 8
  %5 = load i32, i32* %4, align 4
  %idxprom = sext i32 %5 to i64
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom
  %6 = load i32, i32* %arrayidx, align 4
  ret i32 %6
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #1 {
entry:
  %retval = alloca i32, align 4
  store i32 0, i32* %retval, align 4
  %call = call i32 @accessArray(i32 13, i32 4)
  ret i32 %call
}

attributes #0 = { blinded }
