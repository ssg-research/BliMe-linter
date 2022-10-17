#include <stdio.h>
__attribute__((noinline)) int get_blinded_value() {
    return 17;
}

__attribute__((noinline)) int do_stuff(char *buff) {
    printf("%p", buff); // Just to confues the compiler :)
    buff[0] = get_blinded_value();
}
__attribute__((noinline)) int another_one() {
    char buff[10]; // <- not blinded

    do_stuff(buff);

    char c = buff[0]; // <- Is this tracked by VFG?
    printf("%c", c);
}



int main() {
    another_one();
    char buff[10]; // <- not blinded
    // ...
    buff[0] = get_blinded_value();
    
    char c = buff[0]; // <- Is this tracked by VFG?
    printf("%c", c);
    return 0;
}