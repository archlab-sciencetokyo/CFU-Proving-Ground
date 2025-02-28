GCC := 		riscv32-unknown-elf-gcc
OBJCOPY := 	riscv32-unknown-elf-objcopy
OBJDUMP :=	riscv32-unknown-elf-objdump

.PHONY: prog build run tar clean

all: prog build

build:
	verilator --binary --top-module top --Wno-WIDTHTRUNC --Wno-WIDTHEXPAND -o top *.v
	gcc -O2 dispemu/dispemu.c -o build/dispemu -lcairo -lX11

prog:
	mkdir -p build
	$(GCC) -O2 -march=rv32im -mabi=ilp32 -nostartfiles -Tprog/link.ld -Iprog -o build/main.elf prog/crt0.s prog/*.c main.c
	$(OBJDUMP) -D build/main.elf > build/main.dump
	$(OBJCOPY) -O binary build/main.elf build/main.bin.tmp
	dd if=build/main.bin.tmp of=build/main.bin conv=sync bs=16KiB
	rm -f build/main.bin.tmp
	hexdump -v -e '1/4 "%08x\n"' build/main.bin > build/main.32.hex
	tmp_IFS=$$IFS; IFS= ; \
	cnt=0; \
	{ \
		echo "initial begin"; \
		while read -r line; do \
			echo "    ram[$$cnt] = 32'h$$line;"; \
			cnt=$$((cnt + 1)); \
		done < build/main.32.hex; \
		echo "end"; \
	} > sample1.txt; \
	IFS=$$tmp_IFS;

run:
	./obj_dir/top | build/dispemu

proj_name = $(shell basename $(shell pwd))
bitstream:
	@if [ ! -f sample1.txt ]; then \
		echo "Please run 'make prog' first."; \
		exit 1; \
	fi
	vivado -mode batch -source scripts/build.tcl
	cp vivado/$(proj_name).runs/impl_1/main.bit build/.

clean:
	rm -rf obj_dir build rvcpu-32im* sample1.txt vivado* .Xil
