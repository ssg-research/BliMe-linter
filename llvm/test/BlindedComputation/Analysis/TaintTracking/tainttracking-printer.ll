; RUN: opt -passes="print<taint-tracking>" -S -disable-output < %s 2>&1 | FileCheck %s

@key = dso_local global i32 5, align 4 #0
@keyBlinded = dso_local global i32 0, align 4 #0

; CHECK-LABEL: Taint Tracking for function: main
; CHECK: Tainted Registers:
; CHECK-DAG: {{^ *}}%0
; CHECK: Argument Users:
; CHECK: Tainted Function Arguments:

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #1 {
entry:
  %retval = alloca i32, align 4
  store i32 0, i32* %retval, align 4
  %0 = load i32, i32* @key, align 4
  store i32 %0, i32* @keyBlinded, align 4
  ret i32 0
}

attributes #0 = { blinded }