    b *0x7c00
    layout asm
    set disassembly-flavor intel
    target remote | qemu-system-i386 -S -gdb stdio -m 16 -boot c -hda build/hdd.iso
