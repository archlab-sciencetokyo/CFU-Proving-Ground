# CFU Proving Ground

## Memory Map

| address                 | type    | desription        |
| ----------------------- | ------- | ----------------- |
| 0x00000000 - 0xFFFFFFFF | ROM     | imem              |
| 0x10000000 - 0x00002FFF | RAM     | 12 KiB dmem       |
| 0x20000000 - 0x2FFFFFFF | RAM     | 256 MiB DDR3      |
| 0x40000000 - 0x4FFFFFFF | -       | LiteDRAM Config   |
| 0x80000000 - 0x8000FFFF | -       | 64 KiB vmem       |
| 0xF0000000 - 0xFFFFFFFF | -       | MMIO              |

## MMIO
| address    | R/W     | desription |
| ---------- | ------- | ---------- |
| 0xF0000000 | W       | LED 4      |
| 0xF0000004 | W       | LED 5      |
| 0xF0000008 | W       | LED 6      |
| 0xF000000C | W       | LED 7      |
| 0xF0001004 | R       | UART RX    |
| 0xF0002000 | W       | Perf Reset |
| 0xF0002004 | W       | Pref Start(1) / Stop(0) |
| 0xF0002008 | R       | Perf Counter[31:0]  |
| 0xF000200C | R       | Perf Counter[63:32] |
