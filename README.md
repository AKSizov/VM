# GPU Passthrough Windows 10 Setup
A handful of scripts that use qemu without libvirt to make a working Windows machine with GPU passthrough.
This is my GPU accelerated windows 10 VM machine setup that I use for gaming.
Tested on Arch Linux, but anything else should work too.
## Hardware
These scripts works fine on a muxless laptop with an RTX 2080 and an i9-9980HK.
AMD might be supported, have not tested.
# Manual installation
1. Download QEMU's source code from [here](https://github.com/qemu/qemu)
2. Rename `QEMU DEVICE XYZ` to your desired device in the files `hw/ide/core.c`, `hw/scsi/scsi-disk.c`, `hw/ide/atapi.c`, and `hw/usb/dev-wacom.c`
3. Change `KVMKVMKVM\\0\\0\\0` in `target/i386/kvm.c` to your desired PC model
4. Change `padstr` inside of `hw/ide/atapi.c`
5. Change `bochs` `block/bochs.c`

Credit to [This guide](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/) for helping with the QEMU patches
## Resources
Undetectable VM: [https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/)

Prevent VM exits through RDTSC: [https://github.com/WCharacter/RDTSC-KVM-Handler](https://github.com/WCharacter/RDTSC-KVM-Handler)
