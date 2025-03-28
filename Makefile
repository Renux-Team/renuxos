# ==========================
# Renux OS Makefile
# ==========================

# Default target architecture for the project
ARCH ?= x86_64-renux

# Target configuration file based on the architecture
TARGET = config/arch/$(ARCH).json

# Number of jobs to run in parallel (default: number of CPU cores)
JOBS ?= $(shell nproc)

# Workspace to build
BUILD_WORKSPACE = main

# ==========================
# Default Target
# ==========================
all: init_submodules build_renux

# ==========================
# Build Targets
# ==========================

# Build the project using cargo rustc with the specified target and number of jobs
build_renux:
	@echo "==> Starting build process"
	@if RUSTC_WRAPPER=sccache \
		RUSTFLAGS="-C opt-level=z -C codegen-units=16 -C prefer-dynamic -C inline-threshold=1000" \
		cargo +nightly bootimage -p $(BUILD_WORKSPACE) --target=$(TARGET) -j $(JOBS) -vv; then \
		echo "==> Build process completed. Run with 'make run'"; \
	else \
		echo "==> Build process failed"; \
		exit 1; \
	fi

# Initialize and update git submodules
init_submodules:
	@echo "==> Initializing git submodules"
	@git submodule update --init --recursive

# Run the menuconfig utility to configure the kernel
menuconfig:
	@echo "==> Running menuconfig"
	@RUSTC_WRAPPER=sccache \
		cargo +stable run -p menuconfig -j $(JOBS) -vv -- \
		-C link-arg=-fuse-ld=mold \
		-C linker=clang \
		-C codegen-units=16 \
		-C opt-level=z \
		-C target-cpu=native

# ==========================
# Run and Clean Targets
# ==========================

# Run the Renux OS in QEMU
run:
	@echo "==> Running Renux OS in QEMU"
	@qemu-system-x86_64 -drive format=raw,file=target/$(ARCH)/debug/bootimage-main.bin

# Clean the project by removing the target directory
clean:
	@echo "==> Cleaning project"
	@cargo clean -vv

# ==========================
# Phony Targets
# ==========================
.PHONY: all init_submodules build_renux clean menuconfig run
