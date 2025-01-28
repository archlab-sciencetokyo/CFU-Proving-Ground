.PHONY: all build prog run tar clean

GCC := rv32im-fullcfu/bin/riscv32-unknown-elf-gcc
OBJCOPY := rv32im-fullcfu/bin/riscv32-unknown-elf-objcopy
OBJDUMP := rv32im-fullcfu/bin/riscv32-unknown-elf-objdump

build: prog
	verilator --binary --top-module top --Wno-WIDTHTRUNC --Wno-WIDTHEXPAND -o top *.v
	gcc -O2 prog/dispemu.c -o build/dispemu -lcairo -lX11

prog:
	mkdir -p build
	$(GCC) -O2 -march=rv32im -mabi=ilp32 -nostartfiles -Tprog/link.ld -o build/main.elf prog/crt0.s prog/st7789.c prog/perf.c prog/main.c
	$(OBJDUMP) -D build/main.elf > build/main.dump
	$(OBJCOPY) -O binary build/main.elf build/main.bin.tmp
	dd if=build/main.bin.tmp of=build/main.bin conv=sync bs=16KiB
	rm -f build/main.bin.tmp
	hexdump -v -e '1/4 "%08x\n"' build/main.bin > build/main.32.hex
	cnt=0; \
	{ \
		echo "initial begin"; \
		while IFS= read -r line; do \
			echo "    ram[$$cnt] = 32'h$$line;"; \
			cnt=$$((cnt + 1)); \
		done < build/main.32.hex; \
		echo "end"; \
	} > sample1.txt

run:
	./obj_dir/top | build/dispemu

clean:
	rm -rf obj_dir build rvcpu-32im* sample1.txt vivado_* vivado.* .Xil
