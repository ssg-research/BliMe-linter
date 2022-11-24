// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s -check-prefix=NEWFUNC
// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s -check-prefix=RETURNS
// XFAIL: *
int arr[100];

__attribute__((blinded)) int blind_sink = 0;
int plain_sink = 0;

// We expect to have 1 new variants of this function, such that it has both
// blinded inputs and outputs. We also expect that the original function
// remains as is, without any blinded in-/out-puts.
// 
// NEWFUNC: define {{.*}} @addOne({{.*}}[[ATTRIBUTE_PLAIN:#[0-9]+]] {{( *![a-z0-9]+)*}} {
// NEWFUNC: define {{.*}} @addOne{{\.[a-z0-9]+}}({{.*}}[[ATTRIBUTE_BLINDED:#[0-9]+]] {{( *![a-z0-9]+)*}} {
// NEWFUNC-NOT: attributes [[ATTRIBUTE_PLAIN]]{{.*}}blinded
// NEWFUNC: attributes [[ATTRIBUTE_BLINDED]]{{.*}}blinded
//
__attribute__((noinline))
int addOne(int i) {
	return i + 1;
}

// We expect this function to be marked blinded because one of the addOne calls
// should be converted to a blinded function and hence cause this to return a
// blinded value also.
// 
// RETURNS: @do_stuff{{.*}}[[ATTRIBUTE_BLINDED:#[0-9]+]] {{( *![a-z0-9]+)*}} {
// RETURNS: attributes [[ATTRIBUTE_BLINDED]]{{.*}}blinded
__attribute__((noinline))
int do_stuff(__attribute__((blinded)) int blinded, int plain) {
  // Expect addOne(blinded) to have blinded return value, consequently we also
  // expect this function to be converted to a blinded version.
  return addOne(blinded) + addOne(plain);
}

int main() {
	do_stuff(1, 1);
  return 0;
}
