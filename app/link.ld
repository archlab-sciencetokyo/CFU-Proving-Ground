/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

OUTPUT_ARCH("riscv")
ENTRY(_start)

PROVIDE(IMEM_SIZE = 0x00008000);
PROVIDE(DMEM_SIZE = 0x00004000);

MEMORY {
    imem : ORIGIN = 0x00000000, LENGTH = IMEM_SIZE
    dmem : ORIGIN = 0x10000000, LENGTH = DMEM_SIZE
}

SECTIONS
{
    .text : {
        *(.text.init)
        *(.text.*)
        *(.text)
    } > imem

    .data : {
        *(.data.*)
        *(.sdata*)
        *(.data)
    } > dmem

    .rodata : {
        *(.rodata.*)
        *(.srodata.*)
        *(.rodata)
    } > dmem

    .bss : {
        *(.bss.*)
        *(.sbss)
        *(.bss)
        *(COMMON)
        _end = .;
    } > dmem

    /DISCARD/ : {
        *(.debug*)
    }
}

PROVIDE(_tohost = 0x80000000);
PROVIDE(_fstack = ORIGIN(dmem) + LENGTH(dmem));
