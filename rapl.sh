#!/bin/bash
# MSR
# PL1
echo 145000000 | sudo tee /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw # 145 watt
echo 999000000 | sudo tee /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_0_time_window_us # 999 sec
# PL2
echo 145000000 | sudo tee /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw # 145 watt
echo 2440 | sudo tee /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/constraint_1_time_window_us # 0.00244 sec

# MCHBAR
# PL1
echo 145000000 | sudo tee /sys/devices/virtual/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_0_power_limit_uw # 145 watt
# ^ Only required change on a ASUS Zenbook UX430UNR
echo 999000000 | sudo tee /sys/devices/virtual/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_0_time_window_us # 999 sec
# PL2
echo 145000000 | sudo tee /sys/devices/virtual/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_1_power_limit_uw # 145 watt
echo 2440 | sudo tee /sys/devices/virtual/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_1_time_window_us # 0.00244 sec
