GCC     := /home/share/cad/rv32ima/bin/riscv32-unknown-elf-gcc
GPP     := /home/share/cad/rv32ima/bin/riscv32-unknown-elf-g++
OBJCOPY := /home/share/cad/rv32ima/bin/riscv32-unknown-elf-objcopy
OBJDUMP := /home/share/cad/rv32ima/bin/riscv32-unknown-elf-objdump
VIVADO  := /tools/Xilinx/Vivado/2024.1/bin/vivado
RTLSIM  := /usr/local/bin/verilator

TARGET ?= arty_a7

.PHONY: build prog run clean
build: prog
	$(RTLSIM) --binary --trace --top-module top --Wno-WIDTHTRUNC --Wno-WIDTHEXPAND -o top *.v
	gcc -O2 dispemu/dispemu.c -o build/dispemu -lcairo -lX11

prog:
	mkdir -p build
	$(GPP) -O2 -march=rv32im -mabi=ilp32 -nostartfiles -Iapp -Tapp/link.ld -o build/main.elf app/crt0.s app/*.c main.c 
	$(OBJDUMP) -D build/main.elf > build/main.dump
	$(OBJCOPY) -O binary --only-section=.text build/main.elf build/memi.bin.tmp; \
	$(OBJCOPY) -O binary --only-section=.data \
						 --only-section=.rodata \
						 --only-section=.bss \
						 --only-section=.misc \
						 build/main.elf build/memd.bin.tmp; \
	for suf in i d; do \
		dd if=build/mem$$suf.bin.tmp of=build/mem$$suf.bin conv=sync bs=4KiB; \
		rm -f build/mem$$suf.bin.tmp; \
		hexdump -v -e '1/4 "%08x\n"' build/mem$$suf.bin > build/mem$$suf.32.hex; \
		tmp_IFS=$$IFS; IFS= ; \
		cnt=0; \
		{ \
			echo "initial begin"; \
			while read -r line; do \
				echo "    $${suf}mem[$$cnt] = 32'h$$line;"; \
				cnt=$$((cnt + 1)); \
			done < build/mem$$suf.32.hex; \
			echo "end"; \
		} > mem$$suf.txt; \
		IFS=$$tmp_IFS; \
	done

run:
	./obj_dir/top

drun:
	./obj_dir/top | build/dispemu 1

proj_name = $(shell basename $(shell pwd))
bit:
	@if [ ! -f sample1.txt ]; then \
		echo "Please run 'make prog' first."; \
		exit 1; \
	fi
	$(VIVADO) -mode batch -source build.tcl
	cp vivado/$(proj_name).runs/impl_1/main.bit build/.
	cp -f vivado/$(proj_name).runs/impl_1/main.ltx build/.

init:
	cp constr/$(TARGET).xdc main.xdc
	cp constr/build_$(TARGET).tcl build.tcl

clean:
	rm -rf obj_dir rvcpu-32im* vivado* .Xil

reset-hard:
	rm -rf obj_dir build rvcpu-32im* sample1.txt vivado* .Xil build.tcl main.xdc
