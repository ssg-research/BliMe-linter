// RUN: opt -passes="blinded-instr-conv" -S < %s | FileCheck %s
// XFAIL: *
// Current transformation cannot expand the array with undetermined bound
// In function one_dimension, the transformation fails to expand arr[do_stuff(1)] access

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

__attribute__((noinline))
int one_dimension(char *arr) {
  return arr[do_stuff(1)];
}

// CHECK: stuff...
int main(int argc, char **argv) {
  return one_dimension(argv[0]);
}