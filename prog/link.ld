/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

OUTPUT_ARCH("riscv")
ENTRY(_start)

INCLUDE region.ld

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
