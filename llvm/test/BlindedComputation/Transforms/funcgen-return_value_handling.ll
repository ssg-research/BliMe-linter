; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s -check-prefix=NEWFUNC
; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s -check-prefix=RETURNS

; CFLAGS: --target=riscv64 -Wall -Xclang -disable-lifetime-markers -fno-discard-value-names -fno-unroll-loops -O2

; 
; int arr[100];
; 
; __attribute__((blinded)) int blind_sink = 0;
; int plain_sink = 0;
; 
; We expect to have 1 new variants of this function, such that it has both
; blinded inputs and outputs. We also expect that the original function
; remains as is, without any blinded in-/out-puts.
; 
; NEWFUNC: define {{.*}} @addOne({{.*}}[[ATTRIBUTE_PLAIN:#[0-9]+]] {
; NEWFUNC: define {{.*}} @addOne{{\.[a-z0-9]+}}({{.*}}[[ATTRIBUTE_BLINDED:#[0-9]+]] {
; NEWFUNC-NOT: attributes [[ATTRIBUTE_PLAIN]]{{.*}}blinded
; NEWFUNC: attributes [[ATTRIBUTE_BLINDED]]{{.*}}blinded
; //
; __attribute__((noinline))
; int addOne(int i) {
; 	return i + 1;
; }
; 
; We expect this function to be marked blinded because one of the addOne calls
; should be converted to a blinded function and hence cause this to return a
; blinded value also.
; 
; RETURNS: @do_stuff{{.*}}[[ATTRIBUTE_BLINDED:#[0-9]+]] {
; RETURNS: attributes [[ATTRIBUTE_BLINDED]]{{.*}}blinded
; __attribute__((noinline))
; int do_stuff(__attribute__((blinded)) int blinded, int plain) {
;   // Expect addOne(blinded) to have blinded return value, consequently we also
;   // expect this function to be converted to a blinded version.
;   return addOne(blinded) + addOne(plain);
; }
; 
; int main() {
; 	do_stuff(1, 1);
;   return 0;
; }



; ModuleID = 'BlindedComputation/Transforms/funcgen-return_value_handling.c'
source_filename = "BlindedComputation/Transforms/funcgen-return_value_handling.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128"
target triple = "riscv64"

define dso_local void @doNothingCharPP(i8** nocapture) {
  ret void
}

define dso_local void @doNothingIntPP(i32** nocapture) {
  ret void
}

define dso_local void @doNothingCharP(i8* nocapture) {
  ret void
}

define dso_local void @doNothingIntP(i32* nocapture) {
  ret void
}

@blind_sink = dso_local local_unnamed_addr global i32 0, align 4 #0
@plain_sink = dso_local local_unnamed_addr global i32 0, align 4
@arr = dso_local local_unnamed_addr global [100 x i32] zeroinitializer, align 4

; Function Attrs: noinline norecurse nounwind readnone
define dso_local signext i32 @addOne(i32 signext %i) local_unnamed_addr #1 {
entry:
  %add = add nsw i32 %i, 1
  ret i32 %add
}

; Function Attrs: noinline norecurse nounwind readnone
define dso_local signext i32 @do_stuff(i32 blinded signext %blinded, i32 signext %plain) local_unnamed_addr #1 {
entry:
  %call = tail call signext i32 @addOne(i32 signext %blinded)
  %call1 = tail call signext i32 @addOne(i32 signext %plain)
  %add = add nsw i32 %call1, %call
  ret i32 %add
}

; Function Attrs: norecurse nounwind readnone
define dso_local signext i32 @main() local_unnamed_addr #2 {
entry:
  ret i32 0
}

attributes #0 = { blinded }
attributes #1 = { noinline norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+a,+c,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+a,+c,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64"}
!2 = !{i32 1, !"SmallDataLimit", i32 8}
!3 = !{!"clang version 11.0.0"}
