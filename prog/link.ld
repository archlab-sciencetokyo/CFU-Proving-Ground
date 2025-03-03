OUTPUT_ARCH("riscv")
ENTRY("_start")

SECTIONS
{
    . = 0x00000000;
    .text.init : { *(.text.init) }
    .text.startup : { *(.text.startup) }
    .text : { *(.text) }
    . = ALIGN(0x1000);
    .data : { *(data) }
    . = ALIGN(0x1000);
    .rodata : { *(.rodata) }
    . = ALIGN(0x1000);
    .bss : { *(.bss) }
    _end = .;
}
