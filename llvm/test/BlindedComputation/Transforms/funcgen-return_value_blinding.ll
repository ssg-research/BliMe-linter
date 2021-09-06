; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

; CFLAGS: --target=riscv64 -Wall -Xclang -disable-lifetime-markers -fno-discard-value-names -fno-unroll-loops -O2

; XFAIL: *
; FIXME: Add proper checks here and remove XFAIL.
; 
; int arr[100];
; 
; int zero(int idx) {
; 	return 0 * idx;
; }
; 
; int accessArray(int idx) {
; 	return arr[idx];
; }
; 
; int transform(int idx, int scale, int offset) {
; 	return scale * idx + offset;
; }
; 
; int useKey2(__attribute__((blinded)) int idx) {
; 	return zero(accessArray(transform(idx, 2, 1))) + accessArray(transform(0, 0, 0));
; }
; 
; int main() {
; 	return useKey2(5);
; }



; ModuleID = 'BlindedComputation/Transforms/return_value_blinding.c'
source_filename = "BlindedComputation/Transforms/return_value_blinding.c"
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

@arr = dso_local local_unnamed_addr global [100 x i32] zeroinitializer, align 4

; Function Attrs: norecurse nounwind readnone
define dso_local signext i32 @zero(i32 signext %idx) local_unnamed_addr #0 {
entry:
  ret i32 0
}

; Function Attrs: norecurse nounwind readonly
define dso_local signext i32 @accessArray(i32 signext %idx) local_unnamed_addr #1 {
entry:
  %idxprom = sext i32 %idx to i64
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom
  %0 = load i32, i32* %arrayidx, align 4, !tbaa !4
  ret i32 %0
}

; Function Attrs: norecurse nounwind readnone
define dso_local signext i32 @transform(i32 signext %idx, i32 signext %scale, i32 signext %offset) local_unnamed_addr #0 {
entry:
  %mul = mul nsw i32 %scale, %idx
  %add = add nsw i32 %mul, %offset
  ret i32 %add
}

; Function Attrs: norecurse nounwind readonly
define dso_local signext i32 @useKey2(i32 blinded signext %idx) local_unnamed_addr #1 {
entry:
  %0 = load i32, i32* getelementptr inbounds ([100 x i32], [100 x i32]* @arr, i64 0, i64 0), align 4, !tbaa !4
  ret i32 %0
}

; Function Attrs: norecurse nounwind readonly
define dso_local signext i32 @main() local_unnamed_addr #1 {
entry:
  %0 = load i32, i32* getelementptr inbounds ([100 x i32], [100 x i32]* @arr, i64 0, i64 0), align 4, !tbaa !4
  ret i32 %0
}

attributes #0 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+a,+c,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { norecurse nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+a,+c,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64"}
!2 = !{i32 1, !"SmallDataLimit", i32 8}
!3 = !{!"clang version 11.0.0"}
!4 = !{!5, !5, i64 0}
!5 = !{!"int", !6, i64 0}
!6 = !{!"omnipotent char", !7, i64 0}
!7 = !{!"Simple C/C++ TBAA"}
