# CFU Proving Ground
CFU Proving Ground is a hardware-software co-design environment for FPGAs based on the RISC-V architecture.
This enables agile development of ASIPs (Application-Specific Integrated Products) through a soft processor supporting the RV32IM instruction set, an RTL-based design flow, and a CFU (Custom Function Unit), which is a resource-efficient ALU-based accelerator.

For information on how to create and use Custom Function Units (CFUs), please see [CFU Implementation Guide](cfu.md).

The recommended OS is Ubuntu Linux.
This project has been verified using Vivado **2024.2**.

All changelogs are described in [CHANGELOG.md](CHANGELOG.md).

## Step (1) : Install the required software

If you are using [ACRi Room](https://gw.acri.c.titech.ac.jp/wp/), these software are already installed and you can skip this step.

For RTL simulation, install Verilator version 5 if it is not installed.
See the [Verilator website](https://www.veripool.org/verilator/) for more information.

As an FPGA development tool, install Vivado **2024.2** if it is not installed.
See the  [Vivado site](https://www.amd.com/ja/products/software/adaptive-socs-and-fpgas/vivado.html) for more information.

Our display simulator uses libcairo-deb package, please install it with the following command.
```
$ sudo apt -y install libcairo-dev
```

Please install the RISC-V compiler with the following commands. Installing the compiler can take a long time, so if you don't need it, just skip this.
```
$ sudo apt -y install autoconf automake autotools-dev curl python3 libmpc-dev
$ sudo apt -y install libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo
$ sudo apt -y install gperf libtool patchutils bc zlib1g-dev libexpat-dev
$ git clone https://github.com/riscv-collab/riscv-gnu-toolchain
$ cd riscv-gnu-toolchain
$ ./configure prefix=/tools/cad/riscv/rv32ima --with-arch=rv32ima --with-abi=ilp32
$ make
```

## Step (2) : Clone the repository and edit the environment variables

Please clone this repository with the following command.
```
$ git clone https://github.com/archlab-sciencetokyo/CFU-Proving-Ground
```

Open and edit the `Makefile` on the CFU-Proving-Ground directory to specify proper absolute paths.

If you are using [ACRi Room](https://gw.acri.c.titech.ac.jp/wp/), these paths are already set correctly and you do not need to change them.

| variable   |  path to                     |
| -----------| -----------------------------|
| GCC        | riscv32-unknown-elf-gcc      |
| GPP        | riscv32-unknown-elf-g++      |
| OBJCOPY    | riscv32-unknown-elf-objcopy  |
| OBJDUMP    | riscv32-unknown-elf-objdump  |
| VIVADO     | vivado                       |
| RTLSIM     | verilator                    |

## Step (3) : RTL simulation of main.c on a RISC-V processor with display emulator
This project uses Verilator and a custom display emulator.
The following command is used to compile the project.
```
$ cd CFU-Proving-Ground
$ make
```

The simulation with the display emulator is executed with the following command.
```
$ make drun
```

![sim](figures/sim.png)

The simulation will not finish. Please press Ctrl + C in the terminal to end the simulation.

## Step (4) : Run the RISC-V processor on an FPGA board

Memory initialization files `memi.txt` and `memd.txt` are compiled from `main.c` with the following command.
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

Generate a bitstream file with the following command:
```
$ make bit
```
The generated bitstream file is copied in `build/main.bit`.
Configure and run FPGA with this `main.bit`.
When the FPGA is configured, an application displays many random characters, similar to the simulation.

> [!NOTE]
> Note that a mini display (ST7789 TFT LCD) should be appropriately connected to the Pmod JC of Arty A7-35T FPGA board.
> ![arty](figures/arty.JPG)
> This [site](https://github.com/kisek/fpga_arty_a7_st7789) will explain the way to connect a mini display to Arty A7-35T FPGA board.
>
> For Nexys A7, connect to JXADC.
> ![nexys](figures/nexys.JPEG)
>

## Memory Map
The default memory map is shown below.
The sizes of instruction memory and data memory can be changed in `config.vh`.
If you change the size of the data memory, please appropriately modify the LENGTH of dmem in `app/link.ld`.

| addr   |  description                     |
| -----------| -----------------------------|
| 0x00000000 - 0x00007FFF | 32KiB Instruction Memory     |
| 0x10000000 - 0x10003FFF | 16KiB Data Memory            |
| 0x20000000 - 0x2000FFFF | 64KiB Video Memory    |
| 0x40000000 | performance counter control (0: reset, 1: start, 2: stop)|
| 0x40000004 | mcycle                  |
| 0x40000008 | mcycleh                 |
| 0x80000000 | tohost (reserved) |

## Write a bitstream
When using the Vivado Hardware Server, you can use `scripts/prog_dev.tcl`.

In `scripts/prog_dev.tcl`, please specify the IP ADDRESS and PORT number of the host where the Vivado Hardware Server is running.
Once the specification is complete, you can write the bitstream to the board with `make conf`.

## How to Modify Memory Size?
To change the memory size, you must modify the configuration on both the hardware and software sides.

### Hardware Side
On the hardware side, you can change the memory size by modifying the `config.vh` file.
The unit is in bytes.
For example, if you want to use 64KiB of DMEM (Data Memory), you would set: `` `define DMEM_SIZE (64*1024) ``

```verilog
// ram
`define IMEM_SIZE (32*1024) // instruction memory size in byte
`define DMEM_SIZE (16*1024) // data memory size in byte
```

### Software Side
The compiler is unaware of the amount of memory the hardware provides. The user must specify this configuration using the linker script (`app/link.ld`).

Specifically, you need to change the `LENGTH` value in the `MEMORY` section of `app/link.ld`.

For example, if the hardware has 64KiB of DMEM, you would set the `LENGTH` to `0x00010000` (which is 65,536, or 64 * 1024): `dmem : ORIGIN = 0x10000000, LENGTH = 0x00010000`
```
MEMORY {
    imem : ORIGIN = 0x00000000, LENGTH = 0x00008000
    dmem : ORIGIN = 0x10000000, LENGTH = 0x00004000
}
```
> [!NOTE]
> Even if FPGA board havs sufficient Block RAM, you might be unable to generate a bitstream in Vivado when you increase the size of the `dmem`.
> This is likely because the `dmem` description does not adhere to the Vivado User Guide.
