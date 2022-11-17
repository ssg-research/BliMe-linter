; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

@arr = dso_local local_unnamed_addr global [100 x i8] zeroinitializer, align 16

; CHECK-LABEL: @accessArray(
; CHECK-NOT:     getelementptr inbounds [100 x i8], [100 x i8]* @arr, i64 0, i64 {{%.*}}
; COM: CHECK:         getelementptr inbounds ([100 x i8], [100 x i8]* @arr, i64 0, i64 0)
; CHECK:    br label %[[LOOPBODY:.*]]

; CHECK:       [[LOOPBODY]]:
; CHECK-NEXT:    [[INDUCVAR:%.*]] = phi i64 [ 0, [[ENTRY:%.*]] ], [ [[PREVINDUC:%.*]], %[[LOOPBODY]] ]
; CHECK-NEXT:    [[CURELEMENT:%.*]] = phi i8 [ [[INITIALELEMENT:%.*]], [[ENTRY]] ], [ [[PREVELEMENT:%.*]], %[[LOOPBODY]] ]
; CHECK-NEXT:    [[BLINDEDADDR:%.*]] = getelementptr [100 x i8], [100 x i8]* @arr, i64 0, i64 [[INDUCVAR]]
; CHECK-NEXT:    load i8, i8* [[BLINDEDADDR]], align 1
; CHECK-NEXT:    icmp eq i64 [[INDUCVAR]], [[INDEX:%.*]]
; Disable the follwoing since they're incompatible with the select transforms
; DISABLE-CHECK-NEXT:    [[RET:%.*]] = select i1 [[COND:%.*]], i8 [[LOADRESULT:%.*]], i8 [[CURELEMENT]]
; DISABLE-CHECK-NEXT:    [[PREVINDUC]] = add nsw i64 [[INDUCVAR]], 1
; DISABLE-CHECK-NEXT:    icmp slt i64 [[INDUCVAR]], 100
; DISABLE-CHECK-NEXT:    br i1 [[BRCOND:%.*]], label %[[LOOPBODY]], label %[[AFTERLOOP:.*]]
; DISABLE-CHECK:       [[AFTERLOOP]]:
; DISABLE-CHECK-NEXT:    ret i8 [[RET]]

; Function Attrs: noinline nounwind optnone uwtable
define dso_local signext i8 @accessArray(i32 blinded %index) #0 {
entry:
  %index.addr = alloca i32, align 4
  store i32 %index, i32* %index.addr, align 4
  %0 = load i32, i32* %index.addr, align 4
  %idxprom = sext i32 %0 to i64
  %arrayidx = getelementptr inbounds [100 x i8], [100 x i8]* @arr, i64 0, i64 %idxprom
  %1 = load i8, i8* %arrayidx, align 1
  ret i8 %1
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
entry:
  %call = call signext i8 @accessArray(i32 5)
  ret i32 0
}