; RUN: FileCheck %s < <(opt -passes="print<blinded-data-usage>" -S < %s 2>&1)

; CHECK: loadInstr with a blinded pointer!

@n = dso_local global i32 50, align 4
@arr = dso_local global i8* null, align 8

; Function Attrs: noinline nounwind optnone uwtable
define dso_local signext i8 @accessArray(i32 blinded %index) #0 {
entry:
  %index.addr = alloca i32, align 4
  store i32 %index, i32* %index.addr, align 4
  %0 = load i8*, i8** @arr, align 8
  %1 = load i32, i32* %index.addr, align 4
  %idxprom = sext i32 %1 to i64
  %arrayidx = getelementptr inbounds i8, i8* %0, i64 %idxprom
  %2 = load i8, i8* %arrayidx, align 1
  ret i8 %2
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  store i32 0, i32* %retval, align 4
  %0 = load i32, i32* @n, align 4
  %conv = sext i32 %0 to i64
  %mul = mul i64 %conv, 1
  %call = call noalias i8* @malloc(i64 %mul) #2
  store i8* %call, i8** @arr, align 8
  %call1 = call signext i8 @accessArray(i32 5)
  ret i32 0
}

; Function Attrs: nounwind
declare dso_local noalias i8* @malloc(i64) #1
