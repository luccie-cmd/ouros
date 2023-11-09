ASM=nasm
LD=ld
GCC=gcc
STAGE1_ASM_FLAGS=-fbin
SRC_DIR=src
BUILD_DIR=build
STAGE1_DIR=$(SRC_DIR)/bootloader/stage1
STAGE2_DIR=$(SRC_DIR)/bootloader/stage2

SOURCES_C=$(wildcard $(STAGE2_DIR)/*.c)
OBJECTS_C=$(patsubst $(STAGE2_DIR)/%.c, $(BUILD_DIR)/stage2/c/%.o, $(SOURCES_C))

all: always iso

always:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/stage2
	mkdir -p $(BUILD_DIR)/stage2/asm
	mkdir -p $(BUILD_DIR)/stage2/c

iso: stage1 stage2
	dd if=/dev/zero of=$(BUILD_DIR)/os.iso count=2880 bs=512
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/os.iso
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/os.iso conv=notrunc
	@mcopy -i $(BUILD_DIR)/os.iso $(BUILD_DIR)/stage2.bin "::stage2.bin"

stage1:
	$(ASM) $(STAGE1_ASM_FLAGS) $(STAGE1_DIR)/main.asm -o $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage2/c/%.o: $(STAGE2_DIR)/%.c
	@echo "--> Compiling: " $<
	@$(GCC) -m32 -ffreestanding -nostdlib -fno-PIC -Werror -Wall -Wextra -c -o $@ $<
	@echo "--> Compiled: " $<

stage2: $(OBJECTS_C)
	$(ASM) -f elf -o $(BUILD_DIR)/stage2/asm/main.o $(STAGE2_DIR)/main.asm
	$(LD) -m elf_i386 -T $(STAGE2_DIR)/linker.ld -o $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/stage2/asm/*.o $(BUILD_DIR)/stage2/c/*.o
