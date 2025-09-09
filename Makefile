# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit 

export GCC := /tools/cad/riscv/rv32ima/bin/riscv32-unknown-elf-gcc
GPP     := /tools/cad/riscv/rv32ima/bin/riscv32-unknown-elf-g++
OBJCOPY := /tools/cad/riscv/rv32ima/bin/riscv32-unknown-elf-objcopy
OBJDUMP := /tools/cad/riscv/rv32ima/bin/riscv32-unknown-elf-objdump
VIVADO  := /tools/Xilinx/Vivado/2024.1/bin/vivado
VPP     := /tools/Xilinx/Vitis/2024.1/bin/v++
RTLSIM  := /tools/cad/bin/verilator

TARGET := arty_a7
#TARGET := cmod_a7
#TARGET := nexys_a7

USE_HLS ?= 0

.PHONY: sim prog imem_image dmem_image remove-junk bit load run drun clean regressive-test
all: user_config prog imem_image dmem_image remove-junk sim

user_config:
	mkdir -p build
	python3 scripts/user_config.py

sim:
	$(RTLSIM) --binary --trace --top-module top -Ibuild -Isrc \
	--Wno-WIDTHTRUNC --Wno-WIDTHEXPAND --Wno-COMBDLY --Wno-CASEINCOMPLETE \
	-o top src/*.v
	gcc -O2 dispemu/dispemu.c -o build/dispemu -lcairo -lX11

prog:
	$(MAKE) -C prog -f prog.mk

boot_image:
	$(MAKE) -C boot -f boot.mk
	$(OBJDUMP) -d build/boot.elf > build/boot.dump
	$(OBJCOPY) -O binary --only-section=.text build/boot.elf build/bootrom_init.bin
	dd if=build/bootrom_init.bin of=build/bootrom_init.img conv=sync bs=1KiB
	hexdump -v -e '1/4 "%08x\n"' build/bootrom_init.img > build/bootrom_init.32.hex
	{ \
		cnt=0; \
		echo "initial begin"; \
		while read line; do \
			echo "    rom[$$cnt] = 32'h$$line;"; \
			cnt=$$((cnt + 1)); \
		done < build/bootrom_init.32.hex; \
		echo "end"; \
	} > build/bootrom_init.vh

imem_image:
	$(OBJDUMP) -d build/main.elf > build/main.dump
	$(OBJCOPY) -O binary --only-section=.text build/main.elf build/bootrom_init.bin
	dd if=build/bootrom_init.bin of=build/bootrom_init.img conv=sync bs=1KiB
	hexdump -v -e '1/4 "%08x\n"' build/bootrom_init.img > build/bootrom_init.32.hex
	{ \
		cnt=0; \
		echo "initial begin"; \
		while read line; do \
			echo "    rom[$$cnt] = 32'h$$line;"; \
			cnt=$$((cnt + 1)); \
		done < build/bootrom_init.32.hex; \
		echo "end"; \
	} > build/bootrom_init.vh

dmem_image:
	$(OBJCOPY) -O binary build/main.elf --only-section=.data   \
								     --only-section=.rodata \
									 --only-section=.bss    \
									 build/sdram_init.bin
	dd if=build/sdram_init.bin of=build/sdram_init.img bs=1k conv=sync
	hexdump -v -e '1/4 "%08x\n"' build/sdram_init.img > build/sdram_init.32.hex
	{ \
		cnt=0; \
		echo "initial begin"; \
		while read line; do \
			echo "    ram[$$cnt] = 32'h$$line;"; \
			cnt=$$((cnt + 1)); \
		done < build/sdram_init.32.hex; \
		echo "end"; \
	} > build/sdram_init.vh

remove-junk:
	rm -f build/bootrom_init.bin build/bootrom_init.img build/bootrom_init.32.hex
	rm -f build/sdram_init.bin build/sdram_init.img build/sdram_init.32.hex

bit:
	mkdir -p vivado
	cd vivado && \
	$(VIVADO) -mode batch -source ../scripts/build_$(TARGET).tcl

load:
	$(VIVADO) -mode batch -source scripts/load.tcl

run:
	./obj_dir/top

drun:
	./obj_dir/top | build/dispemu 1

clean:
	rm -rf build/ obj_dir/ vivado/ 

#================
# Remove when regression test is done
#================
ELF_FILES := $(wildcard tests/*.elf)
regression-test:
	for f in $(ELF_FILES); do \
		cp $${f} build/main.elf; \
		make imem_image dmem_image > /dev/null; \
		make sim > /dev/null; \
		echo "Running $$f ..."; \
		./obj_dir/top; \
	done

TEST ?= addi
single-test:
	mkdir -p build
	make user_config
	cp tests/rv32ui-p-$(TEST).elf build/main.elf
	make imem_image dmem_image > /dev/null
	make remove-junk > /dev/null
	make sim > /dev/null
	./obj_dir/top

