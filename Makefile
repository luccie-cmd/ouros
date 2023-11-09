ASM=nasm
STAGE1_ASM_FLAGS=-fbin
SRC_DIR=src
BUILD_DIR=build
STAGE1_DIR=$(SRC_DIR)/bootloader/stage1
STAGE2_DIR=$(SRC_DIR)/bootloader/stage2

all: iso

iso: stage1 stage2
	dd if=/dev/zero of=$(BUILD_DIR)/os.iso count=2880 bs=512
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/os.iso
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/os.iso conv=notrunc
	@mcopy -i $(BUILD_DIR)/os.iso $(BUILD_DIR)/stage2.bin "::stage2.bin"

stage1:
	mkdir -p build
	$(ASM) $(STAGE1_ASM_FLAGS) $(STAGE1_DIR)/main.asm -o $(BUILD_DIR)/stage1.bin

stage2:
	mkdir -p build
	$(ASM) $(STAGE1_ASM_FLAGS) $(STAGE2_DIR)/main.asm -o $(BUILD_DIR)/stage2.bin