make -B always
make -B iso
qemu-system-i386 -hda build/os.iso
