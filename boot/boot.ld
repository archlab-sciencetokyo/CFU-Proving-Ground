/* CFU Proving Ground since 2025-02   Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit          */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    bootrom (r)  : ORIGIN = 0x00000000, LENGTH = 4K
    sdram   (rwx): ORIGIN = 0x00001000, LENGTH = 4K
}

SECTIONS
{
    .text : {
        *(.text.init)
        *(.text.*)
        *(.text)
    } > bootrom

    .data : {
        *(.data.*)
        *(.sdata*)
        *(.data)
    } > sdram
    
    .rodata : {
        *(.rodata.*)
        *(.srodata.*)
        *(.rodata)
    } > sdram

    .bss : {
        *(.bss.*)
        *(.sbss)
        *(.bss)
        *(COMMON)
    } > sdram
}

PROVIDE (_esdram = ORIGIN(sdram) + LENGTH(sdram));
