; RUN: FileCheck %s < <(opt -passes="print<blinded-data-usage>" -S < %s 2>&1)

; CHECK: Invalid use of blinded data as operand of BranchInst!

; Function Attrs: noinline nounwind optnone uwtable
define dso_local signext i8 @evenOrOdd(i32 blinded %number) #0 {
entry:
  %retval = alloca i8, align 1
  %number.addr = alloca i32, align 4
  store i32 %number, i32* %number.addr, align 4
  %0 = load i32, i32* %number.addr, align 4
  %rem = srem i32 %0, 2
  %cmp = icmp eq i32 %rem, 0
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  store i8 69, i8* %retval, align 1
  br label %return

if.else:                                          ; preds = %entry
  store i8 79, i8* %retval, align 1
  br label %return

return:                                           ; preds = %if.else, %if.then
  %1 = load i8, i8* %retval, align 1
  ret i8 %1
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  store i32 0, i32* %retval, align 4
  %call = call signext i8 @evenOrOdd(i32 5)
  %call1 = call signext i8 @evenOrOdd(i32 8)
  ret i32 0
}
