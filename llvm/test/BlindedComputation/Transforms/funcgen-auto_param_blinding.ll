; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

; CFLAGS: --target=riscv64 -Wall -Xclang -disable-lifetime-markers -fno-discard-value-names -fno-unroll-loops -O2

; 
; int arr[100];
; 
; We expect to have 6 new variants of this function!
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; CHECK-LABEL: define {{.*}} @accessArray{{\.[a-z0-9]+}}(
; __attribute__((noinline))
; int accessArray(int idx, int idx2, int idx3) {
; 	return arr[idx] + arr[idx2] + arr[idx3];
; }
; 
; __attribute__((noinline))
; int useKey(__attribute__((blinded)) int idx) {
; 	return accessArray(idx, 1, 1) + accessArray(1, idx, 1) + accessArray(1, 1, idx) + accessArray(2 * idx, 0, idx + 1) + accessArray(idx, idx, idx)
; 		+ accessArray(2 * idx, 3 * idx, idx + 5);
; }
; 
; int main() {
; 	return useKey(5);
; }



; ModuleID = 'BlindedComputation/Transforms/funcgen-auto_param_blinding.c'
source_filename = "BlindedComputation/Transforms/funcgen-auto_param_blinding.c"
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

; Function Attrs: noinline norecurse nounwind readonly
define dso_local signext i32 @accessArray(i32 signext %idx, i32 signext %idx2, i32 signext %idx3) local_unnamed_addr #0 {
entry:
  %idxprom = sext i32 %idx to i64
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom
  %0 = load i32, i32* %arrayidx, align 4, !tbaa !4
  %idxprom1 = sext i32 %idx2 to i64
  %arrayidx2 = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom1
  %1 = load i32, i32* %arrayidx2, align 4, !tbaa !4
  %add = add nsw i32 %1, %0
  %idxprom3 = sext i32 %idx3 to i64
  %arrayidx4 = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom3
  %2 = load i32, i32* %arrayidx4, align 4, !tbaa !4
  %add5 = add nsw i32 %add, %2
  ret i32 %add5
}

; Function Attrs: noinline norecurse nounwind readonly
define dso_local signext i32 @useKey(i32 blinded signext %idx) local_unnamed_addr #0 {
entry:
  %call = tail call signext i32 @accessArray(i32 signext %idx, i32 signext 1, i32 signext 1)
  %call1 = tail call signext i32 @accessArray(i32 signext 1, i32 signext %idx, i32 signext 1)
  %add = add nsw i32 %call1, %call
  %call2 = tail call signext i32 @accessArray(i32 signext 1, i32 signext 1, i32 signext %idx)
  %add3 = add nsw i32 %add, %call2
  %mul = shl nsw i32 %idx, 1
  %add4 = add nsw i32 %idx, 1
  %call5 = tail call signext i32 @accessArray(i32 signext %mul, i32 signext 0, i32 signext %add4)
  %add6 = add nsw i32 %add3, %call5
  %call7 = tail call signext i32 @accessArray(i32 signext %idx, i32 signext %idx, i32 signext %idx)
  %add8 = add nsw i32 %add6, %call7
  %mul10 = mul nsw i32 %idx, 3
  %add11 = add nsw i32 %idx, 5
  %call12 = tail call signext i32 @accessArray(i32 signext %mul, i32 signext %mul10, i32 signext %add11)
  %add13 = add nsw i32 %add8, %call12
  ret i32 %add13
}

; Function Attrs: norecurse nounwind readonly
define dso_local signext i32 @main() local_unnamed_addr #1 {
entry:
  %call = tail call signext i32 @useKey(i32 signext 5)
  ret i32 %call
}

attributes #0 = { noinline norecurse nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+a,+c,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
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
