#!/bin/bash
# you must type info cpus in QEMU monitor for any of this to work
CPU_T_0=$(cat con.log | grep "CPU #0:" | cut -c 21-)
CPU_T_1=$(cat con.log | grep "CPU #1:" | cut -c 21-)
CPU_T_2=$(cat con.log | grep "CPU #2:" | cut -c 21-)
CPU_T_3=$(cat con.log | grep "CPU #3:" | cut -c 21-)
CPU_T_4=$(cat con.log | grep "CPU #4:" | cut -c 21-)
CPU_T_5=$(cat con.log | grep "CPU #5:" | cut -c 21-)
CPU_T_6=$(cat con.log | grep "CPU #6:" | cut -c 21-)
CPU_T_7=$(cat con.log | grep "CPU #7:" | cut -c 21-)
CPU_T_8=$(cat con.log | grep "CPU #8:" | cut -c 21-)
CPU_T_9=$(cat con.log | grep "CPU #9:" | cut -c 21-)
CPU_T_10=$(cat con.log | grep "CPU #10:" | cut -c 22-)
CPU_T_11=$(cat con.log | grep "CPU #11:" | cut -c 22-)
if [ -z "$CPU_T_11" ]; then
    echo "cpu thread 11 not found... exiting!"
    exit 1
fi
#CPU_T_12=$(cat con.log | grep "CPU #12:" | cut -c 22-)
#CPU_T_13=$(cat con.log | grep "CPU #13:" | cut -c 22-)
#CPU_T_14=$(cat con.log | grep "CPU #14:" | cut -c 22-)
#CPU_T_15=$(cat con.log | grep "CPU #15:" | cut -c 22-)
CPU_T_0=${CPU_T_0::-1}
CPU_T_1=${CPU_T_1::-1}
CPU_T_2=${CPU_T_2::-1}
CPU_T_3=${CPU_T_3::-1}
CPU_T_4=${CPU_T_4::-1}
CPU_T_5=${CPU_T_5::-1}
CPU_T_6=${CPU_T_6::-1}
CPU_T_7=${CPU_T_7::-1}
CPU_T_8=${CPU_T_8::-1}
CPU_T_9=${CPU_T_9::-1}
CPU_T_10=${CPU_T_10::-1}
CPU_T_11=${CPU_T_11::-1}
#CPU_T_12=${CPU_T_12::-1}
#CPU_T_13=${CPU_T_13::-1}
#CPU_T_14=${CPU_T_14::-1}
#CPU_T_15=${CPU_T_15::-1}
echo "==> getting CPU threads..."
echo "  -> CPU thread 0 is $CPU_T_0"
echo "  -> CPU thread 1 is $CPU_T_1"
echo "  -> CPU thread 2 is $CPU_T_2"
echo "  -> CPU thread 3 is $CPU_T_3"
echo "  -> CPU thread 4 is $CPU_T_4"
echo "  -> CPU thread 5 is $CPU_T_5"
echo "  -> CPU thread 6 is $CPU_T_6"
echo "  -> CPU thread 7 is $CPU_T_7"
echo "  -> CPU thread 8 is $CPU_T_8"
echo "  -> CPU thread 9 is $CPU_T_9"
echo "  -> CPU thread 10 is $CPU_T_10"
echo "  -> CPU thread 11 is $CPU_T_11"
#echo "  -> CPU thread 12 is $CPU_T_12"
#echo "  -> CPU thread 13 is $CPU_T_13"
#echo "  -> CPU thread 14 is $CPU_T_14"
#echo "  -> CPU thread 15 is $CPU_T_15"
echo "==> shielding processes..."
sudo cset shield --force -s -p $CPU_T_0
sudo cset shield --force -s -p $CPU_T_1
sudo cset shield --force -s -p $CPU_T_2
sudo cset shield --force -s -p $CPU_T_3
sudo cset shield --force -s -p $CPU_T_4
sudo cset shield --force -s -p $CPU_T_5
sudo cset shield --force -s -p $CPU_T_6
sudo cset shield --force -s -p $CPU_T_7
sudo cset shield --force -s -p $CPU_T_8
sudo cset shield --force -s -p $CPU_T_9
sudo cset shield --force -s -p $CPU_T_10
sudo cset shield --force -s -p $CPU_T_11
echo "==> setting cpu affinities..."
sudo taskset -cp 2 $CPU_T_0
sudo taskset -cp 10 $CPU_T_1
sudo taskset -cp 3 $CPU_T_2
sudo taskset -cp 11 $CPU_T_3
sudo taskset -cp 4 $CPU_T_4
sudo taskset -cp 12 $CPU_T_5
sudo taskset -cp 5 $CPU_T_6
sudo taskset -cp 13 $CPU_T_7
sudo taskset -cp 6 $CPU_T_8
sudo taskset -cp 14 $CPU_T_9
sudo taskset -cp 7 $CPU_T_10
sudo taskset -cp 15 $CPU_T_11
#taskset -cp 6 $CPU_T_12
#taskset -cp 14 $CPU_T_13
#taskset -cp 7 $CPU_T_14
#taskset -cp 15 $CPU_T_15
#echo "==> changing priorities..."
# from https://rigtorp.se/low-latency-guide/
# For lowest latency applications I avoid using real-time priorities SCHED_FIFO / SCHED_RR. Instead it’s better to run a single thread in SCHED_OTHER per core and using busy waiting / polling in order to never enter kernel mode. If you do so with real-time priority you can prevent the kernel from running tasks such as vmstat leading to kernel lockup issues.
# To prevent accidental lockups the kernel comes with a feature that by default throttles real-time tasks to use at most 95% of the CPU bandwidth. If you are using real-time tasks you might want to adjust the real-time throttling configuration.
# “Real Time Throttling”. https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/7/html/tuning_guide/real_time_throttling
# “Real-Time group scheduling”. https://www.kernel.org/doc/html/latest/scheduler/sched-rt-group.html
RT_PRI=20
sudo chrt -p -f $RT_PRI $CPU_T_0
sudo chrt -p -f $RT_PRI $CPU_T_1
sudo chrt -p -f $RT_PRI $CPU_T_2
sudo chrt -p -f $RT_PRI $CPU_T_3
sudo chrt -p -f $RT_PRI $CPU_T_4
sudo chrt -p -f $RT_PRI $CPU_T_5
sudo chrt -p -f $RT_PRI $CPU_T_6
sudo chrt -p -f $RT_PRI $CPU_T_7
sudo chrt -p -f $RT_PRI $CPU_T_8
sudo chrt -p -f $RT_PRI $CPU_T_9
sudo chrt -p -f $RT_PRI $CPU_T_10
sudo chrt -p -f $RT_PRI $CPU_T_11
echo "==> done!"
