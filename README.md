# CFU Proving Ground

## Memory Map

| address                 | type    | desription        |
| ----------------------- | ------- | ----------------- |
| 0x00000000 - 0x00000FFF | ROM     | 4 KiB bootrom     |
| 0x00001000 - 0x00001FFF | RAM     | 4 KiB sdram       |
| 0x10000000 - 0x1FFFFFFF | -       | MMIO              |
| 0x20000000 - 0x200707FF | RAM     | 240x240x8bit VMEM | 
| 0x40000000 - 0x4FFFFFFF | **RAM** | IMEM              |
| 0x80000000 - 0x8FFFFFFF | RAM     | 256MiB DDR3       |
| 0xF0000000 - 0xFFFFFFFF | -       | CSRs              |

## MMIO
| address    | R/W     | desription |
| ---------- | ------- | ---------- |
| 0x10000000 | W       | UART TX    |
| 0x10000004 | R       | UART RX    |
