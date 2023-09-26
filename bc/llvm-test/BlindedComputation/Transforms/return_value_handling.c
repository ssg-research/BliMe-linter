// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// Just a meaningless check to avoid failing test case
// CHECK: main
int arr[100];

__attribute__((blinded)) int blind_sink = 0;
int plain_sink = 0;

__attribute__((noinline))
int addOne(int i) {
	return i + 1;
}

__attribute__((noinline))
int do_stuff(__attribute__((blinded)) int blinded, int plain) {
  return addOne(blinded) + addOne(plain);
}

int main(int argc, char **argv) {
	do_stuff(1, 1);
  return argv[0][do_stuff(1, 1)];
}