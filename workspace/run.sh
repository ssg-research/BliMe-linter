# compile blind.c
riscv64-unknown-linux-gnu-gcc -static -g -c blind.c

# link all object files together
/opt/riscv/libexec/gcc/riscv64-unknown-linux-gnu/10.2.0/collect2 -plugin /opt/riscv/libexec/gcc/riscv64-unknown-linux-gnu/10.2.0/liblto_plugin.so -plugin-opt=/opt/riscv/libexec/gcc/riscv64-unknown-linux-gnu/10.2.0/lto-wrapper -plugin-opt=-fresolution=/tmp/ccuHQpEN.res -plugin-opt=-pass-through=-lgcc -plugin-opt=-pass-through=-lgcc_eh -plugin-opt=-pass-through=-lc --sysroot=/opt/riscv/sysroot -melf64lriscv -static -o demo /opt/riscv/sysroot/usr/lib/crt1.o /opt/riscv/lib/gcc/riscv64-unknown-linux-gnu/10.2.0/crti.o /opt/riscv/lib/gcc/riscv64-unknown-linux-gnu/10.2.0/crtbeginT.o -L/opt/riscv/lib/gcc/riscv64-unknown-linux-gnu/10.2.0 -L/opt/riscv/lib/gcc/riscv64-unknown-linux-gnu/10.2.0/../../../../riscv64-unknown-linux-gnu/lib -L/opt/riscv/sysroot/lib -L/opt/riscv/sysroot/usr/lib blind.o final.o --start-group -lgcc -lgcc_eh -lc --end-group /opt/riscv/lib/gcc/riscv64-unknown-linux-gnu/10.2.0/crtend.o /opt/riscv/lib/gcc/riscv64-unknown-linux-gnu/10.2.0/crtn.o

# dump assembly
riscv64-unknown-linux-gnu-objdump -d -M numeric -M no-aliases --visualize-jumps demo > demo.dmp.s

# run in spike
spike /opt/riscv/riscv64-unknown-linux-gnu/bin/pk demo
