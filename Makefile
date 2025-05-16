.PHONY: all download_src download_toolchains build_kernel build_uboot build_opensbi download_rootfs prepare_bootfs genimg clean

SCRIPTS_DIR := script
SHELL := /bin/bash
TOOLCHAIN_DIR := $(shell pwd)/toolchain
TOOLS_DIR := $(shell pwd)/tools
PATH := $(PATH):$(TOOLCHAIN_DIR)/bin:$(TOOLS_DIR)/bin

all: genimg

download_src:
	@echo "→ Step 1: 下载源码"
	@$(SCRIPTS_DIR)/1-download_src.sh

download_toolchains: download_src
	@echo "→ Step 2: 下载工具链"
	@$(SCRIPTS_DIR)/2-download_toolchains.sh

build_kernel: download_toolchains
	@echo "→ Step 3: 编译 Kernel"
	@$(SCRIPTS_DIR)/3-build_kernel.sh

build_uboot: build_kernel
	@echo "→ Step 4: 编译 U-Boot"
	@$(SCRIPTS_DIR)/4-build_uboot.sh

build_opensbi: build_uboot
	@echo "→ Step 5: 编译 OpenSBI"
	@$(SCRIPTS_DIR)/5-build_opensbi.sh

download_rootfs: build_opensbi
	@echo "→ Step 6: 下载 RootFS"
	@$(SCRIPTS_DIR)/6-download_rootfs.sh

prepare_bootfs: download_rootfs
	@if [ -z "${NO_CLEAN:-}" ]; then \
		echo "→ Cleaning src/"; \
		rm -rf src/; \
	else \
		echo "→ Skipping clean (NO_CLEAN is set)"; \
	fi
	@echo "→ Step 7: 准备 BootFS"
	@echo "→ Step 7: 生成initramfs"
	@$(SCRIPTS_DIR)/build_initramfs.sh
	@$(SCRIPTS_DIR)/7-prepare_bootfs.sh

genimg: prepare_bootfs
	@echo "→ Step 8: 生成镜像"
	@$(SCRIPTS_DIR)/8-genimg.sh

clean:
	@echo "→ 清理输出目录"
	rm -rf rootfs/ output/ src/
