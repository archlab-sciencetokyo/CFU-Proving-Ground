# CFU Proving Ground

# Quick Start

`Makefile`を開いて1から6行目の絶対パスを指定します。

| Variable   | Description                  |
| -----------| -----------------------------|
| GCC        | riscv32-unknown-elf-gcc      |
| GPP        | riscv32-unknown-elf-g++      |
| OBJCOPY    | riscv32-unknown-elf-objcopy  |
| OBJDUMP    | riscv32-unknown-elf-objdump  |
| VIVADO     | vivado                       |
| RTLSIM     | verilator                    |

次のコマンドで、main.cのコンパイル、及びtop.vのコンパイルを行います。
```
cd cfu_pg
make
```

次のコマンドでディスプレイの表示を行います。
```
make drun
```

bitstreamの生成を行うにはつぎのコマンドを使用します。
```
make bit
```

生成されたbitstreamは`build/main.bit`に保存されます。


# History

2025-03-03 Ver 0.2:
config.vhからdisplayの方向を変更できるようにした。
通常のターミナルで透過色を使う機会がないので、ここでは、透過色をサポートしない方針にしました。

2025-02-20 Ver.0.1: initial version

--------------------------------------------------------------------------------
Target board     : Cmod A7-100T FPGA board
Target FPGA      : xc7a100tcsg324-1
Mini display     : ST7789 240x240 pixel
--------------------------------------------------------------------------------

