#!/bin/sh

sudo qemu-system-aarch64 -M virt,virtualization=true,gic-version=3 \
	-cpu cortex-a53 -smp 8 -m 4096 \
	-nographic -semihosting \
	-kernel ~/work/minios/output/Image \
	-append "console=ttyAMA0" \
	-initrd ~/work/minios/output/initrd \
	-gdb tcp::1287 \
        -netdev type=tap,id=net0,ifname=tap0,script=no,downscript=no \
	-device virtio-net,netdev=net0
