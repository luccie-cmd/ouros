#!/bin/bash

set -e

./build.sh
qemu-system-i386 -debugcon stdio -m 32 -hda ../build/hdd.iso
