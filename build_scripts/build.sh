#!/bin/bash

set -e

BUILD_DIR=../build
STAGE1_SRC_DIR=../src/bootloader/stage1
STAGE1_BUILD_DIR=../build/bootloader/stage1
STAGE2_SRC_DIR=../src/bootloader/stage2
STAGE2_BUILD_DIR=../build/bootloader/stage2
STAGE2_FILES_ASM=($(find ${STAGE2_SRC_DIR} -name '*.asm'))
STAGE2_FILES_C=($(find ${STAGE2_SRC_DIR} -name '*.c'))
KERNEL_SRC_DIR=../src/kernel
KERNEL_BUILD_DIR=../build/kernel
KERNEL_FILES_ASM=($(find ${KERNEL_SRC_DIR} -name '*.asm'))
KERNEL_FILES_C=($(find ${KERNEL_SRC_DIR} -name '*.c'))
HDD_IMAGE=../build/hdd.iso
CFLAGS="-nostdlib -ffreestanding -Werror -Wall -Wextra -O0"
LDFLAGS=""
TOOLCHAIN_PATH=../toolchain/i686-elf/bin

build_all(){
    setup_dirs
    build_stage1_bootloader
    build_stage2_bootloader
    build_kernel
}

build_stage1_bootloader() {
    echo "Building Stage1 bootloader"
    nasm -fbin ${STAGE1_SRC_DIR}/main.asm -o ${STAGE1_BUILD_DIR}/main.asm.o
    cp ${STAGE1_BUILD_DIR}/main.asm.o ${BUILD_DIR}/stage1.bin
    echo "Done"
}

build_stage2_bootloader() {
    echo "Building Stage2 bootloader"
    for file in "${STAGE2_FILES_ASM[@]}"; do
        echo "Processing: $file"
        base_name=$(basename -s .asm "$file")
        nasm -felf "$file" -o "${STAGE2_BUILD_DIR}/asm/${base_name}.asm.o"
    done
    for file in "${STAGE2_FILES_C[@]}"; do
        echo "Processing: $file"
        base_name=$(basename -s .c "$file")
        ${TOOLCHAIN_PATH}/i686-elf-gcc -c ${CFLAGS} $file -o ${STAGE2_BUILD_DIR}/c/${base_name}.c.o
    done
    echo "Linking Stage2"
    ${TOOLCHAIN_PATH}/i686-elf-gcc ${LDFLAGS} -T ${STAGE2_SRC_DIR}/linker.ld -nostdlib -Wl,-Map=${BUILD_DIR}/stage2.map -o ${BUILD_DIR}/stage2.bin ${STAGE2_BUILD_DIR}/asm/*.o ${STAGE2_BUILD_DIR}/c/*.o -lgcc
    echo "Done"
}

build_kernel() {
    echo "Building kernel"
    for file in "${KERNEL_FILES_ASM[@]}"; do
        echo "Processing: $file"
        base_name=$(basename -s .asm "$file")
        nasm -felf $file -o ${KERNEL_BUILD_DIR}/asm/${base_name}.asm.o
    done
    for file in "${KERNEL_FILES_C[@]}"; do
        echo "Processing: $file"
        base_name=$(basename -s .c "$file")
        ${TOOLCHAIN_PATH}/i686-elf-gcc -c ${CFLAGS} $file -o ${KERNEL_BUILD_DIR}/c/${base_name}.c.o
    done
    echo "Linking kernel"
    ${TOOLCHAIN_PATH}/i686-elf-gcc ${LDFLAGS} -T ${KERNEL_SRC_DIR}/linker.ld -nostdlib -Wl,-Map=${BUILD_DIR}/kernel.map -o ${BUILD_DIR}/kernel.bin ${KERNEL_BUILD_DIR}/c/*.o -lgcc
    echo "Done"
}

setup_dirs(){
    mkdir -p ../build/bootloader/stage1
    mkdir -p ../build/bootloader/stage2
    mkdir -p ../build/bootloader/stage2/c
    mkdir -p ../build/bootloader/stage2/asm
    mkdir -p ../build/kernel
    mkdir -p ../build/kernel/c
    mkdir -p ../build/kernel/asm
}


build_all

# generate image file
dd if=/dev/zero of=${HDD_IMAGE} bs=1M count=2048
SIZE=$(stat -c%s ${HDD_IMAGE})

STAGE1_STAGE2_LOCATION_OFFSET=480

STAGE2_SIZE=$(stat -c%s ${BUILD_DIR}/stage2.bin)
echo ${STAGE2_SIZE}
STAGE2_SECTORS=$(( ( ${STAGE2_SIZE} + 511 ) / 512 ))
echo ${STAGE2_SECTORS}


# create loopback device
DEVICE=$(losetup -f --show ${HDD_IMAGE})
# DEVICE=${HDD_IMAGE}
echo "Created loopback device ${DEVICE}"

# create file system
echo "Formatting ${DEVICE}..."
mkfs.fat -F 32 -n "NBOS" ${DEVICE} >/dev/null

# install bootloader
echo "Installing bootloader on ${DEVICE}..."
dd if=${BUILD_DIR}/stage1.bin of=${DEVICE} conv=notrunc bs=1 count=3 2>&1 >/dev/null
dd if=${BUILD_DIR}/stage1.bin of=${DEVICE} conv=notrunc bs=1 seek=90 skip=90 2>&1 >/dev/null
dd if=${BUILD_DIR}/stage2.bin of=$HDD_IMAGE conv=notrunc bs=512 seek=8 >/dev/null

# write lba address of stage2 to bootloader
echo "08 00 00 00" | xxd -r -p | dd of=$DEVICE conv=notrunc bs=1 seek=$STAGE1_STAGE2_LOCATION_OFFSET
printf "%02x" ${STAGE2_SECTORS} | xxd -r -p | dd of=$DEVICE conv=notrunc bs=1 seek=$(( $STAGE1_STAGE2_LOCATION_OFFSET + 4 ))

# copy files
echo "Copying files to ${DEVICE} (mounted on /tmp/nbos)..."
mkdir -p /tmp/nbos
mount ${DEVICE} /tmp/nbos
# Copy important files
mkdir /tmp/nbos/boot
mkdir /tmp/nbos/boot/kernel
cp ../build/kernel.bin /tmp/nbos/boot/kernel
cp -r ../file_image /tmp/nbos

umount /tmp/nbos

# destroy loopback device
losetup -d ${DEVICE}