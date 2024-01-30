#!/bin/bash

./build.sh

QEMU_ARGS="-S -gdb stdio -m 32"

if [ "$#" -le 1 ]; then
    echo "Usage: ./debug.sh <image_type> <image>"
    exit 1
fi

case "$1" in
    "disk")     QEMU_ARGS="${QEMU_ARGS} -hda $PWD/$2"
    ;;
    *)          echo "Unknown image type $1."
                exit 2
esac

# b *0x7c00
# layout asm
cat > .vscode/.gdb_script.gdb << EOF
    b *0x7c00
    layout asm
    set disassembly-flavor intel
    target remote | qemu-system-i386 -S -gdb stdio -m 32 -boot c -hda build/hdd.iso
EOF

gdb -x .vscode/.gdb_script.gdb