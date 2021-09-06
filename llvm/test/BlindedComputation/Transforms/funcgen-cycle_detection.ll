; RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

; CFLAGS: --target=riscv64 -Wall -Xclang -disable-lifetime-markers -fno-discard-value-names -fno-unroll-loops -O2

; XFAIL: *
; FIXME: Add proper checks here and remove XFAIL.
; 
; int useKey(int idx, int idx2, int noTransform);
; 
; int arr[100];
; 
; int accessArray(int idx) {
; 	return arr[idx];
; }
; 
; int transform(int idx, int scale, int offset) {
; 	return scale * useKey(idx, offset, 1); // will cause cycle
; 	// return scale * (idx + offset); // no cycle
; }
; 
; int useKey(int idx, int idx2, int noTransform) {
; 	if (noTransform) return idx + idx2;
; 
; 	return accessArray(transform(idx + idx2, 2, idx2));
; }
; 
; __attribute__((blinded)) int first = 5;
; __attribute__((blinded)) int second = 3;
; 
; int main() {
; 	return useKey(first, second, 0);
; }



; ModuleID = 'BlindedComputation/Transforms/funcgen-cycle_detection.c'
source_filename = "BlindedComputation/Transforms/funcgen-cycle_detection.c"
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
@first = dso_local local_unnamed_addr global i32 5, align 4 #0
@second = dso_local local_unnamed_addr global i32 3, align 4 #0

; Function Attrs: norecurse nounwind readonly
define dso_local signext i32 @accessArray(i32 signext %idx) local_unnamed_addr #1 {
entry:
  %idxprom = sext i32 %idx to i64
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom
  %0 = load i32, i32* %arrayidx, align 4, !tbaa !4
  ret i32 %0
}

; Function Attrs: nounwind readonly
define dso_local signext i32 @transform(i32 signext %idx, i32 signext %scale, i32 signext %offset) local_unnamed_addr #2 {
entry:
  %add.i = add nsw i32 %offset, %idx
  %mul = mul nsw i32 %add.i, %scale
  ret i32 %mul
}

; Function Attrs: nounwind readonly
define dso_local signext i32 @useKey(i32 signext %idx, i32 signext %idx2, i32 signext %noTransform) local_unnamed_addr #2 {
entry:
  %tobool.not = icmp eq i32 %noTransform, 0
  %add = add nsw i32 %idx2, %idx
  br i1 %tobool.not, label %if.end, label %return

if.end:                                           ; preds = %entry
  %add.i.i = add nsw i32 %add, %idx2
  %mul.i = shl nsw i32 %add.i.i, 1
  %idxprom.i = sext i32 %mul.i to i64
  %arrayidx.i = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom.i
  %0 = load i32, i32* %arrayidx.i, align 4, !tbaa !4
  br label %return

return:                                           ; preds = %entry, %if.end
  %retval.0 = phi i32 [ %0, %if.end ], [ %add, %entry ]
  ret i32 %retval.0
}

; Function Attrs: norecurse nounwind readonly
define dso_local signext i32 @main() local_unnamed_addr #1 {
entry:
  %0 = load i32, i32* @first, align 4, !tbaa !4
  %1 = load i32, i32* @second, align 4, !tbaa !4
  %reass.add = shl i32 %1, 1
  %add.i.i.i = add i32 %reass.add, %0
  %mul.i.i = shl nsw i32 %add.i.i.i, 1
  %idxprom.i.i = sext i32 %mul.i.i to i64
  %arrayidx.i.i = getelementptr inbounds [100 x i32], [100 x i32]* @arr, i64 0, i64 %idxprom.i.i
  %2 = load i32, i32* %arrayidx.i.i, align 4, !tbaa !4
  ret i32 %2
}

attributes #0 = { blinded }
attributes #1 = { norecurse nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+a,+c,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+a,+c,+m,+relax,-save-restore" "unsafe-fp-math"="false" "use-soft-float"="false" }

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
