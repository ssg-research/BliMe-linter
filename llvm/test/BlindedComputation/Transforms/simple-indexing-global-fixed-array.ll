; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

@key = dso_local global i32 5, align 4 #0
@arr = dso_local global [100 x i32] zeroinitializer, align 16

; CHECK-LABEL: @main(
; CHECK:         [[INDEXI32:%.*]] = load i32, i32* @key, align 4
; CHECK:         [[INDEX:%.*]] = sext i32 [[INDEXI32]] to i64
; CHECK-NOT:     getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 {{%.*}}
; COM: CHECK:         getelementptr inbounds ([100 x i32], [100 x i32]* @arr, i64 0, i64 0), align 4
; CHECK:    br label %[[LOOPBODY:.*]]

; CHECK:       [[LOOPBODY]]:
; CHECK-NEXT:    [[INDUCVAR:%.*]] = phi i64 [ 0, [[ENTRY:%.*]] ], [ [[PREVINDUC:%.*]], %[[LOOPBODY]] ]
; CHECK-NEXT:    [[CURELEMENT:%.*]] = phi i32 [ [[INITIALELEMENT:%.*]], [[ENTRY]] ], [ [[PREVELEMENT:%.*]], %[[LOOPBODY]] ]
; CHECK-NEXT:    [[BLINDEDADDR:%.*]] = getelementptr [100 x i32], [100 x i32]* @arr, i64 0, i64 [[INDUCVAR]]
; CHECK-NEXT:    load i32, i32* [[BLINDEDADDR]], align 4
; CHECK-NEXT:    icmp eq i64 [[INDUCVAR]], [[INDEX]]
; Disable the follwoing since they're incompatible with the select transforms
; DISABLE-CHECK-NEXT:    [[RET:%.*]] = select i1 [[COND:%.*]], i32 [[LOADRESULT:%.*]], i32 [[CURELEMENT]]
; DISABLE-CHECK-NEXT:    [[PREVINDUC]] = add nsw i64 [[INDUCVAR]], 1
; DISABLE-CHECK-NEXT:    icmp slt i64 [[INDUCVAR]], 100
; DISABLE-CHECK-NEXT:    br i1 [[BRCOND:%.*]], label %[[LOOPBODY]], label %[[AFTERLOOP:.*]]
; DISABLE-CHECK:       [[AFTERLOOP]]:
; DISABLE-CHECK-NEXT:    ret i32 [[RET]]

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #1 {
entry:
  %retval = alloca i32, align 4
  store i32 0, i32* %retval, align 4
  %0 = load i32, i32* @key, align 4
  %idxprom = sext i32 %0 to i64
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom
  %1 = load i32, i32* %arrayidx, align 4
  ret i32 %1
}

attributes #0 = { blinded }