OUTPUT_ARCH("riscv")
ENTRY("_start")

MEMORY {
    imem : ORIGIN = 0x00000000, LENGTH = 0x00020000
    dmem : ORIGIN = 0x10000000, LENGTH = 0x00020000
}

SECTIONS
{
    .text : {
        . = ALIGN(4);
        *(.text.*)
        *(.text)
        . = ALIGN(4);
    } > imem

    .data : {
        *(.data.*)
        *(.data)
    } > dmem
    
    .rodata : {
        *(.rodata.*)
        *(.rodata)
    } > dmem

    .bss : {
        *(.bss.*)
        *(.bss)
    } > dmem

    .misc : {
        *(COMMON)
        *(.*)
        _end = .;
    } > dmem
}

PROVIDE(_tohost = 0x80000000);
PROVIDE(_fstack = ORIGIN(dmem) + LENGTH(dmem));
