date := $(shell date +%m%d-%H%M)

.PHONY: all build prog run tar clean

build: prog
	verilator --binary --top-module top --Wno-WIDTHTRUNC --Wno-WIDTHEXPAND -o top *.v
	gcc -O2 prog/dispemu.c -o build/dispemu -lcairo -lX11

prog:
	mkdir -p build
	riscv32-unknown-elf-gcc -O2 -march=rv32im -mabi=ilp32 -nostartfiles -Tprog/link.ld -o build/main.elf prog/crt0.s prog/st7789.c prog/main.c
	riscv32-unknown-elf-objdump -D build/main.elf > build/main.dump
	riscv32-unknown-elf-objcopy -O binary build/main.elf build/main.bin.tmp
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

tar:
	mkdir -p rvcpu-32im-$(date)
	cp -r main.v proc.v top.v config.vh Makefile prog build/dispemu rvcpu-32im-$(date)
	tar -zcvf rvcpu-32im-$(date).tar.gz rvcpu-32im-$(date)

clean:
	rm -rf obj_dir build rvcpu-32im* sample1.txt vivado_* vivado.* .Xil