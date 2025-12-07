COREMARK_PRO_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
COREMARK_PRO_SRC := $(COREMARK_PRO_DIR)/coremark-pro-src
COREMARK_PRO_BUILD := $(COREMARK_PRO_SRC)/builds/cfupg/riscv32-cfupg
CFUPG_ROOT := $(realpath $(COREMARK_PRO_DIR)/../..)

WORKLOAD := core
XCMD ?=

.PHONY: coremark-pro-prog
coremark-pro-prog:
	$(MAKE) -C $(COREMARK_PRO_SRC) \
		-I$(COREMARK_PRO_SRC)/util/make \
		-I$(COREMARK_PRO_DIR) \
		TARGET=cfupg \
		TOOLCHAIN=riscv32-cfupg \
		CFUPG_ROOT=$(CFUPG_ROOT) \
		CFUPG_AL_DIR=$(COREMARK_PRO_DIR)/al \
		XCMD="$(XCMD)" \
		wbuild-$(WORKLOAD)
	mkdir -p $(CFUPG_ROOT)/build
	cp $(COREMARK_PRO_BUILD)/bin/core.elf $(CFUPG_ROOT)/build/main.elf
	$(MAKE) -C $(CFUPG_ROOT) initf

.PHONY: coremark-pro
coremark-pro: coremark-pro-prog build

.PHONY: coremark-pro-clean
coremark-pro-clean:
	$(MAKE) -C $(COREMARK_PRO_SRC) \
		-I$(COREMARK_PRO_SRC)/util/make \
		-I$(COREMARK_PRO_DIR) \
		TARGET=cfupg \
		TOOLCHAIN=riscv32-cfupg \
		distclean
	rm -f $(COREMARK_PRO_DIR)/al/src/*.o
	rm -f $(CFUPG_ROOT)/app/*.o
