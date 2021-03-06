#!/bin/bash
cd /tools/vm/
RAM=8G # RAM dedicated for VM
CPUS=12 # vCPUS for guest
if [[ $EUID -ne 0 ]]; then
    echo "Run this with root!"
    exit 1 # qemu and KVM require root access, audio is handled through scream with the right vars
fi
INVIS_FLAGS=kvm=off,hv_vendor_id=null,-hypervisor
HYPERV=$INVIS_FLAGS
echo "==> preparing..."
echo "==> making looking glass..."
touch /dev/shm/looking-glass 
#chown z:kvm /dev/shm/looking-glass
chmod 777 /dev/shm/looking-glass # for looking-glass guest-host display. YOU MUST HAVE A DUMMY PLUG IF USING NVIDIA
echo "==> starting libvirtd..."
systemctl start libvirtd # for network only, I'll remove the libvirt dependency in the future
echo "==> attaching nvme..."
bash -c "echo -n 0000:3d:00.0 > /sys/bus/pci/drivers/nvme/unbind" # detach unused nvme
bash -c "echo vfio-pci > /sys/bus/pci/devices/0000\:3d\:00.0/driver_override" # bind to virtio
bash -c "echo -n 0000:3d:00.0 > /sys/bus/pci/drivers/vfio-pci/bind" # bind to virtio
echo "==> copying pulse cookie for root..."
echo 1 | sudo tee /proc/irq/*/smp_affinity
bash -c "echo -n vfio-pci > /sys/bus/pci/devices/0000:01:00.0/driver_override" # passthrough nvidia gpu, change 0000:01:00.0 to whatever lspci -v says your GPU sits on
echo "==> starting scream in 60 seconds (20ms)..."
#sudo bash -c "sleep 10 && scream -i virbr0 -t 20" & # scream is superior audio, use it if you can.
sleep 10 && PULSE_SERVER=/run/user/1000/pulse/native PULSE_COOKIE=/home/z/.config/pulse/cookie scream -i virbr0 -t 20 & # pulseaudio env because we are root.
# https://bitsum.com/tools/cpu-affinity-calculator/
# 303 = CPUs 0,1,8,9
#sudo bash -c "echo 303 > /sys/bus/workqueue/devices/writeback/cpumask" # cpu bitmask
#echo "==> shutting down picom..."
#echo "==> setting cpu freq..."
#sudo ./freq-max.sh
echo "==> changing rt settings..."
echo -1 | tee /proc/sys/kernel/sched_rt_runtime_us # don't limit cpu to 95% (realtime tasks are throttled to 95% to prevent system lock-ups)
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/7/html/tuning_guide/real_time_throttling
echo "==> start the monstrosity..."
# sudo $z_SHIELD_COMMAND
xhost +
nice -n -18 bash -c "qemu-system-x86_64 \
	-name win10,debug-threads=on `# if we need to take the treads from somewhere else`\
	-pidfile /run/qemu_ex.pid \
	-pflash OVMF-Custom.fd `# UEFI image`\
	-m $RAM `# amount of ram is variable depending on args`\
	-mem-path /dev/hugepages `# hugepages increase ram performance`\
	-cpu max,+invtsc,-vmx,-kvm-poll-control,${HYPERV} `# -cpu host mimics host cpu, -vmx disables virtualization, other flags in variable`\
	-rtc base=localtime,clock=host,driftfix=none `# windows needs localtime rtc`\
	-smp ${CPUS},sockets=1,cores=${z_CORES},threads=2 `# CPU topology`\
	--enable-kvm `# so we can actually get some speed`\
	-mem-prealloc `# prealloc memory`\
	-vga none `# using ramfb below`\
	`#-device ramfb` `# primitive display`\
	--display none `# display ramfb contents`\
	-nodefaults `# don't create CD-ROM, or other "default" devices`\
	-monitor unix:/tmp/qemu.sock,server,nowait `# qemu socket for getting cpu threads and other controls`\
	-boot d `# boot from disk first`\
	-machine type=V_V,kernel_irqchip=on,accel=kvm,smm=off `# using patched QEMU instead of "q35", irqchip for interrupts, smm=off doesn't exit when some cpu call happens`\
	-device ivshmem-plain,memdev=ivshmem,bus=pcie.0 `# used for memory device`\
	-object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=32M `# memory device for looking glass`\
	-acpitable file=max-q.bin `# because i'm using RTX Max-Q, windows requires a battery`\
	-device vfio-pci,host=01:00.0,multifunction=on,romfile=gpu.rom `# my GPU`\
	-device vfio-pci,host=3d:00.0 `# my NVME`\
	-object input-linux,id=kbd1,evdev=/dev/input/by-id/usb-DELL_Technologies_Keyboard-event-kbd,grab_all=on,repeat=on `# keyboard passthrough via evdev`\
	-object input-linux,id=mouse1,evdev=/dev/input/by-id/usb-SINOWEALTH_Game_Mouse-event-mouse `# mouse passthrough via evdev`\
	-device virtio-keyboard-pci,id=input1,bus=pcie.0 `# virtio device`\
	-device virtio-mouse-pci,id=input0,bus=pcie.0 `# virtio mouse` \
	-device ich9-intel-hda,bus=pcie.0,addr=0x1b `# audio input/output`\
	-device hda-micro,audiodev=hda `# audio things`\
	-audiodev pa,id=hda,out.frequency=48000,server=unix:/run/user/1000/pulse/native `# more audio things`\
	-net bridge,br=virbr0 -net nic,model=virtio `# network through libvirtd`\
	-drive if=none,id=stick,file=stick.img `# next 2 lines for bitlocker`\
	-device nec-usb-xhci,id=xhci \
	-device qemu-xhci,id=cam \
	-device usb-storage,bus=xhci.0,drive=stick \
	-usb \
	-device usb-host,hostbus=1,hostport=4 `# passthrough AW lights, not applicable to most people`\
	-device usb-host,hostbus=1,hostport=1 `#  `\
	-device usb-host,bus=cam.0,hostbus=1,hostport=7" &
sleep 3 # give QEMU time to spin
echo "info cpus" | socat - unix-connect:/tmp/qemu.sock > con.log && ./pin.sh
socat -,echo=0,icanon=0 unix-connect:/tmp/qemu.sock
echo "==> removing cpu threads file"
rm -f con.log
if [ "$SHIELD" == "true" ]; then
  echo "==> resetting the cpu shield..."
  sudo cset shield --reset
fi
echo "==> shutting down..."
sudo rm -fv /dev/shm/looking-glass
systemctl stop libvirtd
pkill scream
#sudo ./freq-min.sh
echo "==> shutdown complete!"
#-no-hpet `# trying to force TSC as clock source, much faster than hpet or ACPI PM timer` \
#-device virtio-mouse-pci,id=input0,bus=pcie.0
#-object input-linux,id=mouse1,evdev=/dev/input/by-id/usb-SINOWEALTH_Game_Mouse-event-mouse
#-device vfio-pci,host=01:00.0,multifunction=on,romfile=gpu.ro
#-device ramfb
#-cpu host,rdtscp=off,kvm=off,${HYPERV} \
#-no-hpet \
#rombar=0 ????

#        -drive if=none,id=stick,file=/tools/vm/stick.img \
#        -device nec-usb-xhci,id=xhci \
#        -device usb-storage,bus=xhci.0,drive=stick \

#-nodefaults

#-device usb-host,hostbus=1,hostport=11.1 \
#-device usb-host,hostbus=1,hostport=10

#-device virtio-serial-pci \
#        -chardev spicevmc,id=vdagent,name=vdagent \
#        -device virtserialport,chardev=vdagent,name=com.redhat.spice.0

#        -device virtio-mouse-pci,id=input0,bus=pcie.0,addr=0x4 \
#        -device virtio-keyboard-pci,id=input1,bus=pcie.0,addr=0x5 \
#        -object input-linux,id=mouse1,evdev=/dev/input/by-id/usb-SINOWEALTH_Game_Mouse-event-mouse \
#        -object input-linux,id=kbd1,evdev=/dev/input/by-id/usb-DELL_Technologies_Keyboard-event-kbd,grab_all=on,repeat=on \

#-spice port=5900,addr=127.0.0.1,disable-ticketing \
#-device virtio-mouse-pci,id=mouse2,bus=pcie.0,addr=0x4 \
#-device virtio-keyboard-pci,id=kbd2,bus=pcie.0,addr=0x5 \
#-object input-linux,id=mouse1,evdev=/dev/input/by-id/usb-SINOWEALTH_Game_Mouse-event-mouse \
#-object input-linux,id=kbd1,evdev=/dev/input/by-id/usb-DELL_Technologies_Keyboard-event-kbd,grab_all=on,repeat=on \
#-rtc base=localtime,clock=host,driftfix=none \
#,hv_time,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_vendor_id=NV43FIX,hv-passthrough

#-device ich9-intel-hda,bus=pcie.0,addr=0x1b \
#-device hda-micro,audiodev=hda \
#-audiodev pa,id=hda,out.frequency=48000,server=unix:/run/user/1000/pulse/native \

#-device virtio-scsi-pci,id=scsi0 \
#-drive file=/dev/disk/by-id/nvme-eui.00000000000000018ce38e0300283541,if=none,format=raw,discard=unmap,aio=native,cache=none,id=main \
#-device scsi-hd,drive=main,bus=scsi0.0 \

# -audiodev pa,id=hda,server=unix:/run/user/1000/pulse/native
#-mem-path /hugepages \
#-device vfio-pci,host=01:00.0,xres=1920,yres=1080,display=on
	#-drive file=nvme://0000:3d:00.0/1,if=none,id=drive0 \
	#-device virtio-blk,drive=drive0,id=virtio0
	#-machine type=q35,kernel_irqchip=on \
	#-device virtio-scsi-pci,id=scsi0 \
	#-drive file=/dev/disk/by-id/nvme-eui.00000000000000018ce38e0300283541,if=none,format=raw,discard=unmap,aio=native,cache=none,id=main \
	#-device scsi-hd,drive=main,bus=scsi0.0
	#-bios ./bios.bin \
	#-device virtio-blk,drive=main,id=virtio0
	#-drive file=/dev/idisk/by-id/nvme-eui.00000000000000018ce38e0300283541,if=none,format=raw,discard=unmap,aio=native,cache=none,id=main

	#hv_time,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_vendor_id=NV43FIX,hv-passthrough \"
