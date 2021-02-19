cd /tools/vm/
RAM=10G # RAM dedicated for VM
HOST_CPUS=16 # CPUS on host
CPUS=12 # vCPUS for guest
SHIELD=true # if we isolate these CPUS for the guest exclusively
z_SHIELD_COMMAND="cset shield --exec bash -- -c" # default shielding
if [[ $EUID -eq 0 ]]; then
    echo "Do not run this with root!"
    exit 1 # in order to work with pulseaudio, do not run this script as root
    # it will as for sudo password when starting qemu
fi
if [ $# -eq 0 ]; then
    echo "==> no arguments supplied! Starting with defaults..."
fi
if [ $# -eq 1 ]; then
    echo "==> using $1 of ram..."
    RAM=$1
fi
if [ $# -eq 2 ]; then
    echo "==> using $1 of ram..."
    echo "==> using $2 cpus..."
    RAM=$1
    CPUS=$2
fi
if [ $# -eq 3 ]; then
    echo "==> using $1 of ram..."
    echo "==> using $2 cpus..."
    RAM=$1
    CPUS=$2
    if [ "$3" == "false" ]; then
        echo "==> NOT using shielding..."
	SHIELD=false
	z_SHIELD_COMMAND="bash -c"
    else
        echo "==> using shielding..."
	SHIELD=true
	z_SHIELD_COMMAND="cset shield --exec bash -- -c"
    fi
fi
VIS_FLAGS=hv_time,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_vendor_id=NV43FIX,hv-passthrough,+invtsc
# hyper-v enhancements ^
INVIS_FLAGS=rdtscp=off,kvm=off,hv_vendor_id=18sm9219sb19,-hypervisor
# invisible vm settings ^
HYPERV=$INVIS_FLAGS # change default to whatever you'd like
if [ $# -eq 4 ]; then
    echo "==> using $1 of ram..."
    echo "==> using $2 cpus..."
    RAM=$1
    CPUS=$2
    if [ "$3" == "false" ]; then
        echo "==> NOT using shielding..."
        SHIELD=false
        z_SHIELD_COMMAND="bash -c"
    else
        echo "==> using shielding..."
        SHIELD=true
        z_SHIELD_COMMAND="cset shield --exec bash -- -c"
    fi
    if [ "$4" == "false" ]; then
        echo "==> NOT using hyper-v flags..."
        HYPERV=$INVIS_FLAGS
    else
        echo "==> using hyper-v flags..."
        HYPERV=$VIS_FLAGS
    fi
fi
z_FIRST_HOST_CPU=$((16 - CPUS)) # see line below
z_LAST_HOST_CPU=$((HOST_CPUS - 1)) # not being used right now, configure CPU pinning manually below
z_CORES=$((CPUS / 2)) # ^
echo "==> preparing..."
echo "==> making looking glass..."
sudo touch /dev/shm/looking-glass && sudo chown z:kvm /dev/shm/looking-glass && sudo chmod 660 /dev/shm/looking-glass # for looking-glass guest-host display. YOU MUST HAVE A DUMMY PLUG IF USING NVIDIA
echo "==> starting libvirtd..."
sudo systemctl start libvirtd # for network only, I'll remove the libvirt dependency in the future
echo "==> attaching nvme..."
sudo bash -c "echo -n 0000:3d:00.0 > /sys/bus/pci/drivers/nvme/unbind" # detach unused nvme
sudo bash -c "echo vfio-pci > /sys/bus/pci/devices/0000\:3d\:00.0/driver_override" # bind to virtio
sudo bash -c "echo -n 0000:3d:00.0 > /sys/bus/pci/drivers/vfio-pci/bind" # bind to virtio
echo "==> setting cpu freq to 5Ghz..."
sudo ./freq-max.sh # manually puts CPU at highest clock
echo "==> copying pulse cookie for root..."
sudo cp -v /home/z/.config/pulse/cookie /root/.config/pulse/cookie # important for pulseaudio
if [ "$SHIELD" == "true" ]; then
    echo "==> taking CPUs offline..."
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu15/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu14/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu13/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu12/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu11/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu10/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu7/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu6/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu5/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu4/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu3/online"
    sudo bash -c "echo 0 | sudo tee /sys/devices/system/cpu/cpu2/online"
    echo "==> waiting..."
    sleep 2
    echo "==> bringing CPUs online..."
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu15/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu14/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu13/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu12/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu11/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu10/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu7/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu6/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu5/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu4/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu3/online"
    sudo bash -c "echo 1 | sudo tee /sys/devices/system/cpu/cpu2/online"
    echo "==> setting cpushield on cpus ${z_FIRST_HOST_CPU}-${z_LAST_HOST_CPU}..."
    #sudo cset shield --shield --kthread=on --cpu ${z_FIRST_HOST_CPU}-${z_LAST_HOST_CPU}
    # configure CPU pinning manually!
    # for intel CPUs with hyperthreading, the threads are not next to each other
    # on a 16 cpu machine, cores 1 and 8 are on the same CPU and should be passed through to the guest as such
    # configure the CPU pinning here, configure the exposed guest topology in the qemu command
    sudo cset shield --shield --kthread=on --cpu 2-7,10-15
fi
sudo bash -c "echo -n vfio-pci > /sys/bus/pci/devices/0000:01:00.0/driver_override" # passthrough nvidia gpu, change 0000:01:00.0 to whatever lspci -v says your GPU sits on
echo "==> changing audio priority..." # remove this if there are errors or you are not using pipewire
sudo chrt -p -a --rr 20 $(pidof pipewire-media-session)
sudo chrt -p -a --rr 20 $(pidof pipewire)
sudo chrt -p -a --rr 20 $(pidof pipewire-pulse)
sudo chrt -p -a -rr 19 $(pidof python3)
echo "==> starting scream in 60 seconds (20ms)..."
bash -c "sleep 60 && scream -i virbr0 -t 20" & # scream is superior audio, use it if you can.
sudo bash -c "sync"
echo "1" | sudo tee /proc/irq/*/smp_affinity
sudo bash -c "echo 3 > /proc/sys/vm/drop_caches"
sudo bash -c "echo 1 > /proc/sys/vm/compact_memory"
sudo sysctl vm.nr_hugepages=10 # change hardcoded later
sudo sysctl vm.stat_interval=120
sudo sysctl -w kernel.watchdog=0
# https://bitsum.com/tools/cpu-affinity-calculator/
# 303 = CPUs 0,1,8,9
sudo bash -c "echo 303 > /sys/bus/workqueue/devices/writeback/cpumask" # cpu bitmask
sudo bash -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled" # thp have a negative impact on performance
sudo bash -c "echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor" # change cstates
sudo bash -c "echo 0 > /sys/bus/workqueue/devices/writeback/numa"
echo "==> start the monstrosity..."
# sudo $z_SHIELD_COMMAND
sudo bash -c "time sudo qemu-system-x86_64 \
	-name win10,debug-threads=on `# if we need to take the treads from somewhere else`\
	-pidfile /run/qemu_ex.pid \
	-pflash OVMF-Custom.fd `# UEFI image`\
	-m $RAM `# amount of ram is variable depending on args`\
	-mem-path /dev/hugepages `# hugepages increase ram performance`\
	-cpu host,-vmx,${HYPERV} `# -cpu host mimics host cpu, -vmx disables virtualization, other flags in variable`\
	-rtc base=localtime,clock=host,driftfix=none `# windows needs localtime rtc`\
	-smp ${CPUS},sockets=1,cores=${z_CORES},threads=2 `# CPU topology`\
	--enable-kvm `# so we can actually get some speed`\
	-no-hpet `# no high precision event timer to fix stutters`\
	-mem-prealloc `# prealloc memory`\
	-global ICH9-LPC.disable_s3=1 `# no idea`\
	-global ICH9-LPC.disable_s4=1 `# no idea`\
	-vga none `# using ramfb below`\
	--display gtk `# display ramfb contents`\
	-device ramfb `# very primitive display`\
	-nodefaults `# don't create CD-ROM, or other "default" devices`\
	-monitor stdio `# so we can have a monitor`\
	-boot d `# boot from disk first`\
	-machine type=V_V,kernel_irqchip=on,accel=kvm `# using patched QEMU instead of "q35", irqchip for interrupts, don't remember what smm does`\
	-device ivshmem-plain,memdev=ivshmem,bus=pcie.0 `# used for memory device`\
	-object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=32M `# memory device for looking glass`\
	-acpitable file=/tools/vm/patch.bin `# because i'm using RTX Max-Q, windows requires a battery`\
	-device vfio-pci,host=01:00.0,multifunction=on,romfile=gpu.rom `# my GPU`\
	-device vfio-pci,host=3d:00.0 `# my NVME`\
	-object input-linux,id=mouse1,evdev=/dev/input/by-id/usb-SINOWEALTH_Game_Mouse-event-mouse `# mouse passthrough via evdev`\
	-object input-linux,id=kbd1,evdev=/dev/input/by-id/usb-DELL_Technologies_Keyboard-event-kbd,grab_all=on,repeat=on `# keyboard passthrough via evdev`\
	-device virtio-keyboard-pci,id=input1,bus=pcie.0 `# virtio device`\
	-device virtio-mouse-pci,id=input0,bus=pcie.0 `# virtio device`\
	-device ich9-intel-hda,bus=pcie.0,addr=0x1b `# audio input/output`\
	-device hda-micro,audiodev=hda `# audio things`\
	-audiodev pa,id=hda,out.frequency=48000,server=unix:/run/user/1000/pulse/native `# more audio things`\
	-net bridge,br=virbr0 -net nic,model=virtio `# network through libvirtd`\
	-usb \
	-device usb-host,hostbus=1,hostport=4 `# passthrough AW lights`\
	-S `# start qemu in paused state so we can pin the threads`\
	| tee con.log" `# so we can see the CPU threads`
#-overcommit cpu-pm=on \
if [ "$SHIELD" == "true" ]; then
  echo "==> resetting the cpu shield..."
  sudo cset shield --reset
fi
echo "==> shutting down..."
sudo rm -fv /dev/shm/looking-glass
sudo systemctl stop libvirtd
pkill scream
sudo ./freq-min.sh
echo "==> shutdown complete!"

### random stuff i felt like i should leave just in case ###

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
