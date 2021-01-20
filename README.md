# GPU Passthrough Windows 10 Setup
A handful of scripts that use qemu without libvirt to make a working Windows machine with GPU passthrough.
This is my GPU accelerated windows 10 VM machine setup that I use for gaming.
Tested on Arch Linux, but anything else should work too.
## Hardware
These scripts works fine on a muxless laptop with an RTX 2080 and an i9-9980HK.
AMD might be supported, have not tested.
## Resources
[https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/)
[https://github.com/WCharacter/RDTSC-KVM-Handler](https://github.com/WCharacter/RDTSC-KVM-Handler)
