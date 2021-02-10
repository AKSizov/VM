cd /tools/vm/
RAM=8G
HOST_CPUS=16
CPUS=12
SHIELD=true
z_SHIELD_COMMAND="cset shield --exec bash -- -c"
if [[ $EUID -eq 0 ]]; then
    echo "Do not run this with root!" 
    exit 1
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
INVIS_FLAGS=rdtscp=off,kvm=off,hv_vendor_id=null,-hypervisor
HYPERV=$INVIS_FLAGS
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
z_FIRST_HOST_CPU=$((16 - CPUS))
z_LAST_HOST_CPU=$((HOST_CPUS - 1))
z_CORES=$((CPUS / 2))
echo "==> preparing..."
echo "==> making looking glass..."
sudo touch /dev/shm/looking-glass && sudo chown z:kvm /dev/shm/looking-glass && sudo chmod 660 /dev/shm/looking-glass
echo "==> starting libvirtd..."
sudo systemctl start libvirtd
echo "==> attaching nvme..."
sudo bash -c "echo -n 0000:3d:00.0 > /sys/bus/pci/drivers/nvme/unbind"
sudo bash -c "echo vfio-pci > /sys/bus/pci/devices/0000\:3d\:00.0/driver_override"
sudo bash -c "echo -n 0000:3d:00.0 > /sys/bus/pci/drivers/vfio-pci/bind"
echo "==> setting cpu freq to 5Ghz..."
sudo ./freq-max.sh
echo "==> copying pulse cookie for root..."
sudo cp -v /home/z/.config/pulse/cookie /root/.config/pulse/cookie
if [ "$SHIELD" == "true" ]; then
    echo "==> setting cpushield on cpus ${z_FIRST_HOST_CPU}-${z_LAST_HOST_CPU}..."
    #sudo cset shield --shield --kthread=on --cpu ${z_FIRST_HOST_CPU}-${z_LAST_HOST_CPU}
    sudo cset shield --shield --kthread=on --cpu 2-7,10-15
fi
sudo bash -c "echo -n vfio-pci > /sys/bus/pci/devices/0000:01:00.0/driver_override"
echo "==> changing audio priority..."
sudo chrt -p -a --rr 20 $(pidof pipewire-media-session)
sudo chrt -p -a --rr 20 $(pidof pipewire)
sudo chrt -p -a --rr 20 $(pidof pipewire-pulse)
sudo chrt -p -a -rr 19 $(pidof python3)
echo "==> starting scream in 60 seconds (20ms)..."
bash -c "sleep 60 && scream -i virbr0 -t 20" &
echo "==> start the monstrosity..."
sudo $z_SHIELD_COMMAND "time sudo qemu-system-x86_64 \
	-name win10,debug-threads=on \
	-pidfile /run/qemu_ex.pid \
	-pflash OVMF-Custom.fd \
	-m $RAM \
	-mem-path /dev/hugepages \
	-cpu host,-vmx,${HYPERV} \
	-rtc base=localtime,clock=host,driftfix=none \
	-smp ${CPUS},sockets=1,cores=${z_CORES},threads=2 \
	--enable-kvm \
	-vga none \
	--display gtk \
	-device ramfb \
	-nodefaults \
	-monitor stdio \
	-boot d \
	-machine type=V_V,kernel_irqchip=on,accel=kvm,smm=off \
	-device ivshmem-plain,memdev=ivshmem,bus=pcie.0 \
	-object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=32M \
	-acpitable file=/tools/vm/patch.bin \
	-device vfio-pci,host=01:00.0 \
	-device vfio-pci,host=3d:00.0 \
	-object input-linux,id=mouse1,evdev=/dev/input/by-id/usb-SINOWEALTH_Game_Mouse-event-mouse \
	-object input-linux,id=kbd1,evdev=/dev/input/by-id/usb-DELL_Technologies_Keyboard-event-kbd,grab_all=on,repeat=on \
	-device virtio-keyboard-pci,id=input1,bus=pcie.0 \
	-device virtio-mouse-pci,id=input0,bus=pcie.0 \
	-device ich9-intel-hda,bus=pcie.0,addr=0x1b \
	-device hda-micro,audiodev=hda \
	-audiodev pa,id=hda,out.frequency=48000,server=unix:/run/user/1000/pulse/native \
	-net bridge,br=virbr0 -net nic,model=virtio \
	-usb \
	-device usb-host,hostbus=1,hostport=4 | tee con.log"
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
