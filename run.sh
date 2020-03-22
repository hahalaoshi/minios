#!/bin/sh

sudo qemu-system-aarch64 -M virt,virtualization=true,gic-version=3 \
	-cpu cortex-a53 -smp 8 -m 4096 \
	-nographic -semihosting \
	-kernel ~/workspace/minios/output/Image \
	-append "console=ttyAMA0" \
	-initrd ~/workspace/minios/output/initrd \
	#-net nic -net tap,ifname=20 \
	-gdb tcp::1288 \
