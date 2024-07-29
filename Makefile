REMOTE_HOST ?= arc-qemu-root
REMOTE_PORT ?= 2022
BUGS_DIR := /home/ykolerov/workspace/gdb/bugs
NPROC ?= 4

QEMU_HOME := /tools/qemu-arc
QEMU := $(QEMU_HOME)/bin/qemu-system-arc
QEMU64 := $(QEMU)64
QEMU_FTP := hostfwd=tcp::2021-:21
QEMU_SSH := hostfwd=tcp::2022-:22
QEMU_TLN := hostfwd=tcp::2023-:23
QEMU_GDB := hostfwd=tcp::12345-:12345
QEMU_COMMON_ARGS := \
    -display none -nographic -monitor none \
    -device virtio-rng-pci \
    -netdev user,id=net0,$(QEMU_FTP),$(QEMU_SSH),$(QEMU_TLN),$(QEMU_GDB) \
    -device virtio-net-device,netdev=net0

RSYNC_ARGS := -rpltv --chmod=a+wr

#
# Repositories
#

define clone_git_repository
	mkdir -p $(1)
	cd $(1)
	git -C $(1) init
	git -C $(1) remote remove origin || true
	git -C $(1) remote add origin $(2)
	git -C $(1) fetch --all -p
	git -C $(1) checkout $(3)
	git -C $(1) branch --set-upstream-to=origin/$(3) $(3)
	git -C $(1) pull
endef

clone-buildroot-upstream:
	$(call clone_git_repository,buildroot,https://git.buildroot.net/buildroot,master)

clone-buildroot-synopsys:
	$(call clone_git_repository,buildroot-synopsys,https://github.com/foss-for-synopsys-dwc-arc-processors/buildroot,arc64)

clone-buildroot: clone-buildroot-upstream clone-buildroot-synopsys

update-buildroot-upstream:
	git -C buildroot fetch --all -p
	git -C buildroot pull

update-buildroot-synopsys:
	git -C buildroot-synopsys fetch --all -p
	git -C buildroot-synopsys pull

update-buildroot: update-buildroot-upstream update-buildroot-synopsys

#
# QEMU HS4x
#

.PHONY: \
	run-qemu-hs4x-gnu \
	run-qemu-hs4x-uclibc \
	configure-qemu-hs4x-gnu \
	configure-qemu-hs4x-uclibc \
	build-qemu-hs4x-gnu \
	build-qemu-hs4x-uclibc

run-qemu-hs4x-gnu:
	$(QEMU) $(QEMU_COMMON_ARGS) \
	    -M virt -cpu archs -m 2G -kernel build-qemu-hs4x-gnu/images/vmlinux

run-qemu-hs4x-uclibc:
	$(QEMU) $(QEMU_COMMON_ARGS) \
	    -M virt -cpu archs -m 2G -kernel build-qemu-hs4x-uclibc/images/vmlinux

configure-qemu-hs4x-gnu:
	rm -rf build-qemu-hs4x-gnu
	mkdir -p build-qemu-hs4x-gnu
	make -C buildroot O=$(abspath build-qemu-hs4x-gnu) defconfig DEFCONFIG=../defconfigs/qemu_hs4x_gnu_defconfig

configure-qemu-hs4x-uclibc:
	rm -rf build-qemu-hs4x-uclibc
	mkdir -p build-qemu-hs4x-uclibc
	make -C buildroot O=$(abspath build-qemu-hs4x-uclibc) defconfig DEFCONFIG=../defconfigs/qemu_hs4x_uclibc_defconfig

build-qemu-hs4x-gnu:
	make -C build-qemu-hs4x-gnu -j $(NPROC)

build-qemu-hs4x-uclibc:
	make -C build-qemu-hs4x-uclibc -j $(NPROC)

#
# QEMU HS5x
#

QEMU_HS5X_UCLIBC_BUILD_DIR := build-qemu-hs5x-uclibc

.PHONY: \
	run-qemu-hs5x-uclibc \
	configure-qemu-hs5x-uclibc \
	build-qemu-hs5x-uclibc

run-qemu-hs5x-uclibc:
	$(QEMU) $(QEMU_COMMON_ARGS) \
	    -M virt,ram_start=0 -cpu hs5x -m 2G -kernel $(QEMU_HS5X_UCLIBC_BUILD_DIR)/images/loader

configure-qemu-hs5x-uclibc:
	rm -rf $(QEMU_HS5X_UCLIBC_BUILD_DIR)
	mkdir -p $(QEMU_HS5X_UCLIBC_BUILD_DIR)
	make -C buildroot-synopsys O=$(abspath $(QEMU_HS5X_UCLIBC_BUILD_DIR)) defconfig DEFCONFIG=../defconfigs/qemu_hs5x_uclibc_defconfig

build-qemu-hs5x-uclibc:
	make -C $(QEMU_HS5X_UCLIBC_BUILD_DIR) -j $(NPROC)

#
# QEMU HS6x
#

QEMU_HS6X_GNU_BUILD_DIR := build-qemu-hs6x-gnu

.PHONY: \
	run-qemu-hs6x-gnu \
	configure-qemu-hs6x-gnu \
	build-qemu-hs6x-gnu

run-qemu-hs6x-gnu:
	$(QEMU64) $(QEMU_COMMON_ARGS) \
	    -M virt,ram_start=0 -cpu hs6x -m 2G -kernel $(QEMU_HS6X_GNU_BUILD_DIR)/images/loader

configure-qemu-hs6x-gnu:
	rm -rf $(QEMU_HS6X_GNU_BUILD_DIR)
	mkdir -p $(QEMU_HS6X_GNU_BUILD_DIR)
	make -C buildroot-synopsys O=$(abspath $(QEMU_HS6X_GNU_BUILD_DIR)) defconfig DEFCONFIG=../defconfigs/qemu_hs6x_gnu_defconfig

build-qemu-hs6x-gnu:
	make -C $(QEMU_HS6X_GNU_BUILD_DIR) -j $(NPROC)

#
# HS Development Kit
#

HSDK_HS4X_GNU_BUILD_DIR := build-hsdk-hs4x-gnu

.PHONY: \
	configure-hsdk-hs4x-gnu \
	build-hsdk-hs4x-gnu

configure-hsdk-hs4x-gnu:
	rm -rf $(HSDK_HS4X_GNU_BUILD_DIR)
	mkdir -p $(HSDK_HS4X_GNU_BUILD_DIR)
	make -C buildroot O=$(abspath $(HSDK_HS4X_GNU_BUILD_DIR)) defconfig DEFCONFIG=../defconfigs/hsdk_hs4x_gnu_defconfig

build-hsdk-hs4x-gnu:
	make -C $(HSDK_HS4X_GNU_BUILD_DIR) -j 1

HSDK_HS4X_GNU_EBPF_BUILD_DIR := build-hsdk-hs4x-gnu-ebpf

.PHONY: \
	configure-hsdk-hs4x-gnu-ebpf \
	build-hsdk-hs4x-gnu-ebpf

configure-hsdk-hs4x-gnu-ebpf:
	rm -rf $(HSDK_HS4X_GNU_EBPF_BUILD_DIR)
	mkdir -p $(HSDK_HS4X_GNU_EBPF_BUILD_DIR)
	make -C buildroot O=$(abspath $(HSDK_HS4X_GNU_EBPF_BUILD_DIR)) defconfig DEFCONFIG=../defconfigs/hsdk_hs4x_gnu_ebpf_defconfig

build-hsdk-hs4x-gnu-ebpf:
	make -C $(HSDK_HS4X_GNU_EBPF_BUILD_DIR) -j 1

#
# Setup
#

setup-gdb-hs4x-uclibc:
	rsync --port=$(REMOTE_PORT) $(RSYNC_ARGS) /tools/gdb-arc-linux-uclibc-native/* root@$(REMOTE_HOST):/

setup-gdb-hs4x-gnu:
	rsync --port=$(REMOTE_PORT) $(RSYNC_ARGS) /tools/gdb-arc-linux-gnu-native/* root@$(REMOTE_HOST):/

setup-gdb-hs5x-uclibc:
	rsync --port=$(REMOTE_PORT) $(RSYNC_ARGS) /tools/gdb-arc32-linux-uclibc-native/* root@$(REMOTE_HOST):/

setup-gdb-hs6x-gnu:
	rsync --port=$(REMOTE_PORT) $(RSYNC_ARGS) /tools/gdb-arc64-linux-gnu-native/* root@$(REMOTE_HOST):/

setup-bugs:
	rsync --port=$(REMOTE_PORT) $(RSYNC_ARGS) $(BUGS_DIR)/* root@$(REMOTE_HOST):/root/

setup-hs4x-uclibc: setup-gdb-hs4x-uclibc setup-bugs
setup-hs4x-gnu: setup-gdb-hs4x-gnu setup-bugs
setup-hs5x-uclibc: setup-gdb-hs5x-uclibc setup-bugs
setup-hs6x-gnu: setup-gdb-hs6x-gnu setup-bugs
