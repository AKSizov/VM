#!/bin/bash
vfio-isolate -u /tmp/vfio-undo irq-affinity mask C2-7,10-15 cpu-governor performance C2-7,10-15
