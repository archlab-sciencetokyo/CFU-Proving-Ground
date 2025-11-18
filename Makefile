# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit 

VIVADO  := /tools/Xilinx/Vivado/2024.1/bin/vivado

ROOT_DIR := $(shell pwd)
BUILD_DIR := $(ROOT_DIR)/build

TARGET := arty_a7
#TARGET := cmod_a7
#TARGET := nexys_a7

USE_HLS ?= 0

.PHONY: all build-dir user_config bit remove-junk
all: bit

build-dir:
	mkdir -p $(BUILD_DIR)

user_config: build-dir
	python3 scripts/user_config.py

bit: user_config
	$(MAKE) -C prog -f prog.mk BUILD_DIR=$(BUILD_DIR)
	$(VIVADO) -mode batch -source scripts/build_$(TARGET).tcl

conf:
	vivado -mode batch -source scripts/program_device.tcl

remove-junk:
	rm -f build/bootrom_init.bin build/bootrom_init.img build/bootrom_init.32.hex
	rm -f build/sdram_init.bin build/sdram_init.img build/sdram_init.32.hex
	rm -f build/dram_init.bin build/dram_init.img build/dram_init.32.hex
	rm -f build/imem_init.bin build/imem_init.img build/imem_init.32.hex
