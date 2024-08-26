#!/bin/sh

sudo qemu-system-aarch64 -M virt,virtualization=true,gic-version=3 \
	-cpu cortex-a53 -smp 8 -m 4096 \
	-nographic -semihosting \
	-kernel ~/work/minios/output/Image \
	-append "console=ttyAMA0" \
	-initrd ~/work/minios/output/initrd \
	-gdb tcp::1288 \
        -fsdev local,security_model=passthrough,id=fsdev0,path=/home/momo/work/ \
        -device virtio-9p-device,id=fs0,fsdev=fsdev0,mount_tag=hostshare
