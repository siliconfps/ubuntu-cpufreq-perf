#!/bin/bash
# Ativa o governor "performance" em todos os núcleos
set -e

for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    echo performance > "$cpu/cpufreq/scaling_governor" 2>/dev/null || true
done

echo "CPU governor definido como: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'indisponível')"