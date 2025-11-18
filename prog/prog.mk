# GCC       := /tools/cad/riscv/rv32ima/bin/riscv32-unknown-elf-gcc
# OBJD      := /tools/cad/riscv/rv32ima/bin/riscv32-unknown-elf-objdump
# OBJC      := /tools/cad/riscv/rv32ima/bin/riscv32-unknown-elf-objcopy
GCC       := /home/fujino/tools/rv32i/bin/riscv32-unknown-elf-gcc
OBJD      := /home/fujino/tools/rv32i/bin/riscv32-unknown-elf-objdump
OBJC      := /home/fujino/tools/rv32i/bin/riscv32-unknown-elf-objcopy
VERILATOR := /tools/cad/bin/verilator

CFLAGS  := -march=rv32i -mabi=ilp32 -Os -fno-stack-protector -nostartfiles
LDFLAGS := -Tinclude/cfupg/link.ld

.PHONY: default elf dump
default: 
	$(GCC) $(CFLAGS) -o $(BUILD_DIR)/main.elf -DSYNTHESIS -Iinclude \
	-I../litedram/software/include -Tlink.ld crt0.S main.c sdram.c
	make -f prog.mk images

images:
	$(OBJD) --disassemble-all --disassemble-zeroes $(BUILD_DIR)/main.elf > $(BUILD_DIR)/main.dump
	$(OBJC) -O binary $(BUILD_DIR)/main.elf --only-section=.text $(BUILD_DIR)/main.bin
	dd if=$(BUILD_DIR)/main.bin of=$(BUILD_DIR)/main.img bs=1k conv=sync
	hexdump -v -e '1/4 "%08x\n"' $(BUILD_DIR)/main.img > $(BUILD_DIR)/main.hex
	{ \
		cnt=0; \
		echo "initial begin"; \
		while read line; do \
			echo "    mem[$$cnt] = 32'h$$line;"; \
			cnt=$$((cnt + 1)); \
		done < $(BUILD_DIR)/main.hex; \
		echo "end"; \
	} > $(BUILD_DIR)/imem_init.vh
	$(OBJC) -O binary $(BUILD_DIR)/main.elf --only-section=.data   \
								     --only-section=.rodata \
									 --only-section=.bss    \
									 $(BUILD_DIR)/dram.bin
	dd if=$(BUILD_DIR)/dram.bin of=$(BUILD_DIR)/dram.img bs=1k conv=sync
