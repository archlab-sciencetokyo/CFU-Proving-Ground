# CFU Proving Ground
CFU Proving Groundは柔軟で高度な最適化を実現する開発支援フレームワークであり，RTLベースの設計フローを通じて，アプリケーションに特化したアプリケーション特有のプロセッサの迅速な開発を可能にする．
このプロジェクトは，コンパクトなライブラリ，明瞭なファイル依存関係，および柔軟なメモリマップを提供し，スケーラブルな設計をサポートする．
また，リソース効率の高いALUベースのアクセラレータにより，ソフトウェアによるきめ細やかな制御を実現し，ソフトウェアとハードウェアの整合性を向上させる．
さらに，高速なシミュレータの統合により開発サイクルを短縮し，開発コストを削減する．

また，このプロジェクトはVivado 2024.1を利用して検証されています．

## Setup
Open and edit the `Makefile` to specify proper absolute paths.

| variable   |  path to                     |
| -----------| -----------------------------|
| GCC        | riscv32-unknown-elf-gcc      |
| GPP        | riscv32-unknown-elf-g++      |
| OBJCOPY    | riscv32-unknown-elf-objcopy  |
| OBJDUMP    | riscv32-unknown-elf-objdump  |
| VIVADO     | vivado                       |
| RTLSIM     | verilator                    |

## Use without FPGA board (simulation)
このプロジェクトではシミュレータとしてverilatorと独自のディスプレイシミュレータを用いています．
プロジェクトのコンパイルには以下のコマンドを使用します．
```
$ cd cfu_pg
$ make
```

ディスプレイのシミュレーションは次のコマンドで実行します．
```
$ make drun
```

![sim](figures/sim.png)


## Use with FPGA board
メモリ初期化用のファイル`memi.txt`と`memd.txt`を`main.c`からコンパイルします．
```
$ make prog
```

The default FPGA board is Arty A7. 
If you want to use Nexys A7, modify `Makefile` to use `TARGET=nexys_a7`.
If you want to use Cmod A7, modify `Makefile` to use `TARGET=cmod_a7`.
Copy the proper `main.xdc` and `build.tcl` using the following command.
This initialization is necessary once.
```
$ make init
```

Generate bitstream with the following command:
```
$ make bit
```
The generated bitstream file is copied in `build/main.bit`.
Configure and run FPGA with this `main.bit`.

FPGAにコンフィギュレーションをすると，シミュレーションと同様にランダムに文字が表示されるアプリケーションが起動します．

![arty](figures/arty.JPG)

# Memory Map
デフォルトのメモリマップを以下にしまします．
命令メモリとデータメモリの大きさはconfig.vhで変更できます．
データメモリの大きさを変更した場合，`app/link.ld`のdmemの`LENGTH`を適切に変更してください．

| addr   |  description                     |
| -----------| -----------------------------|
| 0x00000000 - 0x0000FFFF | 64KiB Instruction Memory     |
| 0x10000000 - 0x10003FFF | 16KiB Data Memory            |
| 0x20000000 - 0x2000FFFF | 64KiB Video Memory    |
| 0x40000000 | performance counter control (0: reset, 1: start, 2: stop)|
| 0x40000004 | mcycle                  |
| 0x40000008 | mcycleh                 |
| 0x80000000 | tohost (for simulation) |

# History
2025-03-26 v009 (Ver 0.5):
- The function names in the Proving Ground library have been changed.
- The timing of writing to data memory has been changed from the MA stage to the EX stage.

2025-03-24 Ver 0.4:
- The memory map has been changed.
- We changed from Princeton architecture to Harvard architecture.
- The timing of writing to data memory has been changed from the EX stage to the MA stage.
- `perf_instret()` has been removed.

2025-03-04 Ver 0.3:
- The default application has been changed.
- Changed vmem to 3bit RGB.

2025-03-03 Ver 0.2:
- Fixed to allow changing display direction in `config.vh`.
- We have decided not to support transparent colors.
- Removed `st7789_printf()` and added `LCD_prints()`.
- The method was changed to specify the absolute path in the `Makefile`.
- The g++ compiler is now supported.
- When generating bitstream, the existence of `sample1.txt` is checked.
- Moved `build.tcl` to the home directory.
- The directory `prog` has been changed to `app`.
- Added license file.
- Added a brief explanation to the README.md.
- Changed to use he display emulation with `make drun`.
- In addition to the Nexys A7, we now support the Arty A7.
- Changed Nexys A7 and Arty A7 to not use Clock Wizard.

2025-02-20 Ver.0.1: initial version

---
Target board     : Nexys4-A7           
Target FPGA      : xc7a100tcsg324-1    
Mini display     : ST7789 240x240 pixel
---
