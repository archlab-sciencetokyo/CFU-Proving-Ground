.PHONY: all

all:
	$(GCC) -Os -ffreestanding -nostdlib -nostartfiles \
	-Iinclude -Tboot.ld -o ../build/boot.elf boot.c sdram.c crt0.s
