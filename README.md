# CFU Proving Ground

## Setup
Open the `Makefile` and specify absolute paths.

| variable   |  path to                     |
| -----------| -----------------------------|
| GCC        | riscv32-unknown-elf-gcc      |
| GPP        | riscv32-unknown-elf-g++      |
| OBJCOPY    | riscv32-unknown-elf-objcopy  |
| OBJDUMP    | riscv32-unknown-elf-objdump  |
| VIVADO     | vivado                       |
| RTLSIM     | verilator                    |

## Use without board

compile `main.c` and `top.v`:
```
$ cd cfu_pg
$ make
```

Simulate LCD Display:
```
$ make drun
```

## Use with board
compile `main.c` and generate `sample1.txt`:
```
$ make prog
```

Generate bitstream with the following command:
```
$ make bit
```
The default board is Arty. 
If you want to use Nexys, then use `TARGET=nexys_a7`.
The generated bitstream is saved in `build/main.bit`.

# Memory Map
| addr   |  description                     |
| -----------| -----------------------------|
| 0x00000000 - 0x000200000 | Instruction Memory     |
| 0x10000000 - 0x100200000 | Data Memory            |
| 0x20000000 - 0x200200000 | 128KiB Video Memory    |
| 0x40000000 | performance counter control (0: reset, 1: start, 2: stop)|
| 0x40000004 | mcycle                  |
| 0x40000008 | mcycleh                 |
| 0x80000000 | tohost (for simulation) |

# History
2025-03-26 Ver 0.5:
- Proving Groundのライブラリの関数名を変更しました．
- データメモリへの書き込みタイミングをMAステージからEXステージへ変更しました．

2025-03-24 Ver 0.4:
- メモリマップを変更しました．
- プリンストンアーキテクチャからハーバードアーキテクチャへ変更しました．
- データメモリへの書き込みタイミングをEXステージからMAステージへ変更しました．
- `perf_instret()`を廃止しました．

2025-03-04 Ver 0.3:
- デフォルトのアプリケーションを変更しました。
- vmemを3bit RGBへ変更しました。

2025-03-03 Ver 0.2:
- `config.vh`からdisplayの方向を変更できるようしました。
- 透過色をサポートしない方針にしました。
- `st7789_printf()`を削除し、`LCD_prints()`を追加しました。
- `Makefile`を絶対パスを指定する方式にしました。
- g++コンパイラをサポートしました。
- bitstream生成時に、`sample1.txt`の存在を確認するようにしました。
- `build.tcl`をホームディレクトリへ移動しました。
- ディレクトリ`prog`を`app`へ変更しました。
- ライセンスファイルを追加しました。
- READMEに簡単な説明を追加しました。
- `make drun`でディスプレイを表示するように変更しました。
- Nexys A7の他にArty A7をサポートしました。
- クロックウィザードをNexys A7とArty A7で使用しないように変更しました。

2025-02-20 Ver.0.1: initial version

---
Target board     : Nexys4-A7           
Target FPGA      : xc7a100tcsg324-1    
Mini display     : ST7789 240x240 pixel
---
