// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s

int arr[100];

__attribute__((blinded)) int blind_sink = 0;

__attribute__((noinline))
int addOne(int i) {
	return i + 1;
}

__attribute__((noinline))
int do_stuff(int i) {
  return blind_sink + i;
}

// CHECK: stuff
int main(int argc, char **argv) {
  return argv[0][do_stuff(1)];
}