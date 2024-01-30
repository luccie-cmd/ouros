#!/bin/bash

set -e

mkdir -p toolchain

export CFLAGS="-std=c11 -g"
export ASMFLAGS=""
export CC="gcc"
export CXX="g++"
export LD="gcc"
export ASM="nasm"
export LINKFLAGS=""
export LIBS=""

export TARGET="i686-elf"
export TARGET_ASM="nasm"
export TARGET_ASMFLAGS=""
export TARGET_CFLAGS="-std=c11 -g"  # You can modify this as needed
export TARGET_CC="${TARGET}-gcc"
export TARGET_CXX="${TARGET}-g++"
export TARGET_LD="${TARGET}-gcc"
export TARGET_LINKFLAGS=""
export TARGET_LIBS=""

export SOURCE_DIR="$(realpath .)"
export BUILD_DIR="$(realpath build)"

BINUTILS_VERSION="2.42"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"

GCC_VERSION="13.2.0"
GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"

TOOLCHAIN_PREFIX=$(realpath ./toolchain/${TARGET})
export PATH="${TOOLCHAIN_PREFIX}/bin:${PATH}"

# Function to download a file if not present
download_file() {
    FILENAME=$1
    URL=$2
    if [ ! -f "${FILENAME}" ]; then
        mkdir -p toolchain
        cd toolchain || exit
        wget "${URL}"
        cd ..
    fi
}

# Build binutils
BINUTILS_SRC=./binutils-${BINUTILS_VERSION}
BINUTILS_BUILD=./binutils-build-${BINUTILS_VERSION}

download_file "${BINUTILS_SRC}.tar.xz" "${BINUTILS_URL}"

if [ ! -f "${TOOLCHAIN_PREFIX}/bin/i686-elf-ld" ]; then
    cd toolchain || exit
    tar -xf "${BINUTILS_SRC}.tar.xz"
    mkdir -p "${BINUTILS_BUILD}"
    cd "${BINUTILS_BUILD}" || exit
    CFLAGS= ASMFLAGS= CC= CXX= LD= ASM= LINKFLAGS= LIBS= ../${BINUTILS_SRC}/configure \
        --prefix="${TOOLCHAIN_PREFIX}" \
        --target=${TARGET} \
        --with-sysroot \
        --disable-nls \
        --disable-werror
    make -j8
    make install
    cd ../..
fi

# Build GCC
GCC_SRC=./gcc-${GCC_VERSION}
GCC_BUILD=./gcc-build-${GCC_VERSION}

download_file "${GCC_SRC}.tar.xz" "${GCC_URL}"

if [ ! -f "${TOOLCHAIN_PREFIX}/bin/i686-elf-gcc" ]; then
    cd toolchain || exit
    tar -xf "${GCC_SRC}.tar.xz"
    mkdir -p "${GCC_BUILD}"
    cd "${GCC_BUILD}" || exit
    CFLAGS= ASMFLAGS= CC= CXX= LD= ASM= LINKFLAGS= LIBS= ../${GCC_SRC}/configure \
        --prefix="${TOOLCHAIN_PREFIX}" \
        --target=${TARGET} \
        --disable-nls \
        --enable-languages=c,c++ \
        --without-headers
    make -j8 all-gcc all-target-libgcc
    make install-gcc install-target-libgcc
    cd ../..
fi

# Clean
if [ "$1" = "clean" ]; then
    rm -rf "${GCC_BUILD}" "${GCC_SRC}" "${BINUTILS_BUILD}" "${BINUTILS_SRC}"
fi
