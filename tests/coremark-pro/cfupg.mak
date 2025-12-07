# Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

PLATFORM = cfupg
SHELL = /bin/bash

ifndef TOOLCHAIN
TOOLCHAIN = riscv32-cfupg
endif

LOAD =
RUN =
RUN_FLAGS =

# Platform specific defines
PLATFORM_DEFINES =

# CMD_SEP - separator between executable and arguments
CMD_SEP =
