OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    imem     : ORIGIN = 0x00000000, LENGTH = 12K
    dmem     : ORIGIN = 0x10000000, LENGTH = 12K
    litedram : ORIGIN = 0x20000000, LENGTH = 256M
    csr      : ORIGIN = 0x40000000, LENGTH = 8K
    vmem     : ORIGIN = 0x80000000, LENGTH = 64K
}

SECTIONS
{
    . = ALIGN(4);
    .text : {
        *(.text.init)
        *(.text.*)
        *(.text)
    } > imem

    . = ALIGN(4);
    .data : {
        *(.data.*)
        *(.sdata*)
        *(.data)
    } > litedram
    
    . = ALIGN(4);
    .rodata : {
        *(.rodata.*)
        *(.srodata.*)
        *(.rodata)
    } > litedram

    .bss : {
        *(.bss.*)
        *(.sbss)
        *(.bss)
        *(COMMON)
        _end = .;
    } > litedram

    /DISCARD/ : {
        *(.debug*)
    }
}

PROVIDE(_fstack = ORIGIN(dmem) + LENGTH(dmem));
