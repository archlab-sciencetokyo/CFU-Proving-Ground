# CFU Proving Ground

## Memory Map

| address                 | type    | desription        |
| ----------------------- | ------- | ----------------- |
| 0x00000000 - 0x00002000 | ROM     | 8 KiB bootrom     |
| 0x10000000 - 0x20000000 | -       | MMIO              |
| 0x20000000 - 0x20070800 | RAM     | 240x240x8bit VMEM | 
| 0x40000000 - 0x50000000 | **RAM** | IMEM              |
| 0x80000000 - 0x90000000 | RAM     | 256MiB DDR3       |

## MMIO
| address    | R/W     | desription |
| ---------- | ------- | ---------- |
| 0x10000000 | W       | UART TX    |
| 0x10000004 | R       | UART RX    |
