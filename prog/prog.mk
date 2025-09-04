.PHONY: all

all:
	$(GCC) -Os -march=rv32im -mabi=ilp32 -nostartfiles -Iinclude -Tlink.ld -o ../build/main.elf \
	-L../build crt0.s main.c include/*.c
