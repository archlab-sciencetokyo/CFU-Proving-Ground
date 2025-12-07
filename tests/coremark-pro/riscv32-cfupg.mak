# Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

# Tools Root Directory
TOOLS = /tools/cad/riscv/rv32ima
TPREF = riscv32-unknown-elf-

# Tools Executables
CC      = $(TOOLS)/bin/$(TPREF)gcc
AS      = $(TOOLS)/bin/$(TPREF)as
LD      = $(TOOLS)/bin/$(TPREF)gcc
AR      = $(TOOLS)/bin/$(TPREF)ar
OBJCOPY = $(TOOLS)/bin/$(TPREF)objcopy
OBJDUMP = $(TOOLS)/bin/$(TPREF)objdump
SIZE    = $(TOOLS)/bin/$(TPREF)size

# Output flags
OBJOUT = -o
COBJT  = -c
CINCD  = -I
CDEFN  = -D
OEXT   = .o
EXEOUT = -o
EXE    = .elf
LIBTYPE = .a
LIBOUT =

# Architecture flags
ARCH_FLAGS = -march=rv32ima -mabi=ilp32

# Compiler flags
COMPILER_FLAGS = -Os $(ARCH_FLAGS) -nostartfiles
COMPILER_FLAGS += -ffunction-sections -fdata-sections
COMPILER_FLAGS += -Wall -Wno-unused-function
COMPILER_FLAGS += $(CDEFN)NDEBUG $(CDEFN)HOST_EXAMPLE_CODE=0

COMPILER_NOOPT = -O0 -g $(ARCH_FLAGS) -nostartfiles
COMPILER_NOOPT += -ffunction-sections -fdata-sections
COMPILER_NOOPT += $(CDEFN)HOST_EXAMPLE_CODE=0

COMPILER_DEBUG = -O0 -g $(ARCH_FLAGS) -nostartfiles
COMPILER_DEBUG += -ffunction-sections -fdata-sections
COMPILER_DEBUG += $(CDEFN)HOST_EXAMPLE_CODE=0 $(CDEFN)BMDEBUG=1 $(CDEFN)THDEBUG=1

PACK_OPTS =

# Select compiler flags based on build type
ifdef DDB
 CFLAGS = $(COMPILER_DEBUG) $(COMPILER_DEFS) $(PLATFORM_DEFS) $(PACK_OPTS)
else
 ifdef DDN
  CFLAGS = $(COMPILER_NOOPT) $(COMPILER_DEFS) $(PLATFORM_DEFS) $(PACK_OPTS)
 else
  CFLAGS = $(COMPILER_FLAGS) $(COMPILER_DEFS) $(PLATFORM_DEFS) $(PACK_OPTS)
 endif
endif
ifdef DDT
 CFLAGS += $(CDEFN)THDEBUG=1
endif

# Warning options
WARNING_OPTIONS = -Wall -Wno-long-long -fsigned-char -Wno-unused

# Compiler defines for bare-metal
COMPILER_DEFINES += FAKE_FILEIO=1
COMPILER_DEFINES += HAVE_FILEIO=0
COMPILER_DEFINES += HAVE_SYS_STAT_H=0
COMPILER_DEFINES += STUB_STAT=1
COMPILER_DEFINES += NO_ALIGNED_ALLOC=1
COMPILER_DEFINES += USE_CLOCK=0
COMPILER_DEFINES += HAVE_PTHREAD=0
COMPILER_DEFINES += USE_NATIVE_PTHREAD=0
COMPILER_DEFINES += USE_SINGLE_CONTEXT=1
COMPILER_DEFINES += AL_THREAD_U32=1
COMPILER_DEFINES += HAVE_STRDUP=0
COMPILER_DEFINES += GCC_INLINE_MACRO=1
COMPILER_DEFINES += NO_RESTRICT_QUALIFIER=1
# Rename workload main so we can wrap it with our own main that sets up XCMD args
COMPILER_DEFINES += main=workload_main

XCMD ?=
COMPILER_DEFS = $(addprefix $(CDEFN),$(COMPILER_DEFINES))
COMPILER_DEFS += $(CDEFN)XCMD_STRING='"$(XCMD)"'
PLATFORM_DEFS = $(addprefix $(CDEFN),$(PLATFORM_DEFINES))

# Additional include paths
COMPILER_INCLUDES = $(CFUPG_ROOT)/app $(CFUPG_AL_DIR)/include

# Override INC_DIRS to put our custom al/include FIRST (before mith/al/include)
# This ensures our th_cfg.h is used instead of the default one
INC_DIRS = $(CFUPG_AL_DIR)/include $(TOPDIR)mith/include $(TOPDIR)mith/al/include

# Linker flags
LINKER_FLAGS = -T$(CFUPG_ROOT)/app/link.ld
LINKER_FLAGS += $(CFUPG_ROOT)/app/crt0.s
LINKER_FLAGS += -Wl,--gc-sections
LINKER_FLAGS += -Wl,-u,_sbrk
LINKER_FLAGS += $(ARCH_FLAGS) -nostartfiles

# Linker libraries
LINKER_LAST = -lm -lgcc

LINKER_INCLUDES =

# Librarian
LIBRARY_FLAGS = scr
ARFLAGS = $(LIBRARY_FLAGS)
LIBRARY = $(AR) $(ARFLAGS)
LIBRARY_LAST =

# Size flags
SIZE_FLAGS =

CFUPG_AL_DIR ?= $(TOPDIR)../al
PLATFORM_AL_SRCS = $(wildcard $(CFUPG_AL_DIR)/src/*.c)
PLATFORM_AL_SRCS += $(wildcard $(CFUPG_ROOT)/app/*.c)
