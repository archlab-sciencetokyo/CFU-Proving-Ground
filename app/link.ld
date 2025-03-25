OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    imem : ORIGIN = 0x00000000, LENGTH = 0x00020000
    dmem : ORIGIN = 0x10000000, LENGTH = 0x00020000
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
