# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

GCC     := /home/dkumagai/.local/riscv-cfu/bin/riscv32-unknown-elf-gcc
GPP     := /home/dkumagai/.local/riscv-cfu/bin/riscv32-unknown-elf-g++
OBJCOPY := /home/dkumagai/.local/riscv-cfu/bin/riscv32-unknown-elf-objcopy
OBJDUMP := /home/dkumagai/.local/riscv-cfu/bin/riscv32-unknown-elf-objdump

RTLSIM  := /usr/bin/verilator
VIVADO  := /usr/bin/vivado
VPP     := /usr/bin/v++

GOWIN_IDE       ?= /home/dkumagai/gowin/IDE
GOWIN_SH        ?= $(GOWIN_IDE)/bin/gw_sh
GOWIN_PRELOAD   ?= /usr/lib/x86_64-linux-gnu/libfreetype.so.6
GOWIN_LIB_PATH  ?= $(GOWIN_IDE)/lib
GOWIN_PROGRAMMER_DIR ?= /home/dkumagai/gowin/Programmer/bin
GOWIN_PROGRAMMER     ?= $(GOWIN_PROGRAMMER_DIR)/programmer_cli
GOWIN_DEVICE         ?= GW2AR-18C

TARGET := arty_a7
# TARGET := cmod_a7
# TARGET := nexys_a7
# TARGET := tangnano20k

USE_HLS ?= 0

PART_arty_a7  := xc7a35tcsg324-1
PART_nexys_a7 := xc7a100tcsg324-1
PART_cmod_a7  := xc7a35ticpg236-1L

HLS_PART = $(or $(PART_$(TARGET)),$(error HLS is not supported for TARGET=$(TARGET)))
HLS_CFG  := constr/cfu_hls.cfg

.PHONY: build prog run bit bit-gowin conf conf-gowin init clean
all: prog build

build:
	$(RTLSIM) --binary --trace --top-module top --Wno-WIDTHTRUNC --Wno-WIDTHEXPAND -o top *.v
	gcc -O2 dispemu/dispemu.c -o build/dispemu -lcairo -lX11

prog:
	mkdir -p build
	$(GCC) -Os -march=rv32im -mabi=ilp32 -nostartfiles -Iapp -Tapp/link.ld -o build/main.elf app/crt0.s app/*.c *.c
	make initf

imem_size =	$(shell grep -oP "\`define\s+IMEM_SIZE\s+\(\K[^)]*" config.vh | bc)
dmem_size =	$(shell grep -oP "\`define\s+DMEM_SIZE\s+\(\K[^)]*" config.vh | bc)
initf:
	$(OBJDUMP) -D build/main.elf > build/main.dump
	$(OBJCOPY) -O binary --only-section=.text build/main.elf build/memi.bin.tmp; \
	$(OBJCOPY) -O binary --only-section=.data \
						 --only-section=.rodata \
						 --only-section=.bss \
						 build/main.elf build/memd.bin.tmp; \
	for suf in i d; do \
		if [ "$$suf" = "i" ]; then \
			mem_size=$(imem_size); \
		else \
			mem_size=$(dmem_size); \
		fi; \
		dd if=build/mem$$suf.bin.tmp of=build/mem$$suf.bin conv=sync bs=$$mem_size; \
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

TCL_ARG := $(if $(filter 1,$(USE_HLS)),--hls,)
bit:
	@if [ ! -f memi.txt ] || [ ! -f memd.txt ]; then \
		echo "Please run 'make prog' first."; \
		exit 1; \
	fi
	@if [ ! -f build.tcl ]; then \
		echo "Please run 'make init' first."; \
		exit 1; \
	fi
ifeq ($(TARGET), tangnano20k) 
	$(MAKE) bit-gowin
else
	$(VIVADO) -mode batch -source build.tcl -tclargs $(TCL_ARG)
	cp vivado/main.runs/impl_1/main.bit build/.
	@if [ -f vivado/main.runs/impl_1/main.ltx ]; then \
		cp -f vivado/main.runs/impl_1/main.ltx build/.; \
	fi
endif

bit-gowin:
	@if [ ! -f memi.txt ] || [ ! -f memd.txt ]; then \
		echo "Please run 'make prog' first."; \
		exit 1; \
	fi
	@test -x "$(GOWIN_SH)" || { \
		echo "Gowin shell not found: $(GOWIN_SH)"; \
		exit 1; \
	}
	@if [ ! -f build.tcl ] || [ ! -f main.cst ] || [ ! -f main.sdc ]; then \
		echo "Please run 'make init TARGET=tangnano20k' first."; \
		exit 1; \
	fi
	env LD_PRELOAD="$(GOWIN_PRELOAD)" \
		GOWIN_IDE="$(GOWIN_IDE)" \
		LD_LIBRARY_PATH="$(GOWIN_LIB_PATH)" \
		"$(GOWIN_SH)" build.tcl
	@test -f gowin/main/impl/pnr/main.fs || { \
		echo "Gowin bitstream was not generated."; \
		exit 1; \
	}
	mkdir -p build
	cp --remove-destination gowin/main/impl/pnr/main.fs build/main.fs
	chmod u+w build/main.fs

conf:
ifeq ($(TARGET), tangnano20k)
	$(MAKE) conf-gowin
else
	@if [ ! -f build/main.bit ]; then \
		echo "Please run 'make bit' first."; \
		exit 1; \
	fi
	$(VIVADO) -mode batch -source scripts/prog_dev.tcl
endif

conf-gowin:
	@if [ ! -f build/main.fs ]; then \
		echo "Please run 'make bit-gowin' first."; \
		exit 1; \
	fi
	@test -x "$(GOWIN_PROGRAMMER)" || { \
		echo "Gowin programmer not found: $(GOWIN_PROGRAMMER)"; \
		exit 1; \
	}
	env LD_LIBRARY_PATH="$(GOWIN_PROGRAMMER_DIR)" \
		"$(GOWIN_PROGRAMMER)" \
		--device "$(GOWIN_DEVICE)" \
		--operation_index 2 \
		--fsFile "$(abspath build/main.fs)" \
		--output "$(abspath build/programmer.log)"

vpp:
	sed -i -E 's/^[[:space:]]*#?[[:space:]]*(part=)/# \1/' $(HLS_CFG)
	sed -i -E 's/^# (part=$(HLS_PART))$$/\1/' $(HLS_CFG)
	@test "$$(grep -c '^part=' $(HLS_CFG))" -eq 1
	$(VPP) -c --mode hls --config $(HLS_CFG) --work_dir vitis
	if [ -d cfu ]; then rm -rf cfu; fi
	mkdir -p cfu
	cp vitis/hls/impl/verilog/*.v cfu/.
	cp -f vitis/hls/impl/verilog/*.tcl cfu/. 2>/dev/null || true

hls-sim:
	make prog
	tmp_files=""; \
	for src in cfu/*.v; do \
		tmp="cfu/.sim_$$(basename "$$src")"; \
		cp "$$src" "$$tmp"; \
		perl -pi -e 's/#0[ \t]+//' "$$tmp"; \
		tmp_files="$$tmp_files $$tmp"; \
	done; \
	trap 'rm -f $$tmp_files' EXIT; \
	$(RTLSIM) --binary --trace --top-module top -DUSE_HLS -Icfu --Wno-TIMESCALEMOD --Wno-WIDTHTRUNC --Wno-WIDTHEXPAND -o top *.v $$tmp_files

init:
	@if [ "$(TARGET)" = "tangnano20k" ]; then \
		cp constr/tangnano20k.cst main.cst; \
		cp constr/tangnano20k.sdc main.sdc; \
	else \
		cp constr/$(TARGET).xdc main.xdc; \
	fi
	cp constr/build_$(TARGET).tcl build.tcl

clean:
	rm -rf obj_dir rvcpu-32im* vivado* gowin .Xil vitis*

reset-hard:
	rm -rf obj_dir build rvcpu-32im* sample1.txt vivado* gowin .Xil build.tcl main.xdc main.cst main.sdc
