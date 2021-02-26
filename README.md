# GPU Passthrough Windows 10 Setup
A handful of scripts that use qemu without libvirt to make a working Windows machine with GPU passthrough.
This is my GPU accelerated windows 10 VM machine setup that I use for gaming.
Tested on Arch Linux, but anything else should work too.
This setup should be undetectable, but KVM/QEMU at it's core is not designed to be.
I'm not responsible if you get banned, but I haven't gotten banned from anything yet with this setup.
## Hardware
These scripts works fine on a muxless laptop with an RTX 2080 and an i9-9980HK.
AMD might be supported, have not tested.
# Manual installation
1. Download QEMU's source code from [here](https://github.com/qemu/qemu)
2. Rename `QEMU DEVICE XYZ` to your desired device in the files `hw/ide/core.c`, `hw/scsi/scsi-disk.c`, `hw/ide/atapi.c`, and `hw/usb/dev-wacom.c`
3. Change `KVMKVMKVM\\0\\0\\0` in `target/i386/kvm.c` to your desired PC model
4. Change `padstr` inside of `hw/ide/atapi.c`
5. Change `bochs` `block/bochs.c`
6. Follow the instructions for [WCharacter/RDTSC-KVM-Handler](https://github.com/WCharacter/RDTSC-KVM-Handler)
7. Change your boot commandline to include the following if you are using intel: 
```
intel_iommu=on iommu=pt vfio-pci.ids=<device ids> nmi_watchdod=0 default_hugepagesz=1G hugepagesz=1G hugepages=<ram in gb> irqaffinity=<non_guest_cpus> isolcpus=<guest_cpus> nohz_full=<guest_cpus> rcu_nocbs=<guest_cpus> cpuidle.off=1
```
Credit to [This guide](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/) for helping with the QEMU patches
## FAQ
TODO

## Resources
Undetectable VM: [https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/)

Prevent VM exits through RDTSC: [https://github.com/WCharacter/RDTSC-KVM-Handler](https://github.com/WCharacter/RDTSC-KVM-Handler)
