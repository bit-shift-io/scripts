#!/usr/bin/env bash


# Test 500 MHz (Uses less power than 600, but often prevents voltage drops)
#echo 500 | sudo tee /sys/class/drm/card0/gt_min_freq_mhz

# If stable, try 450 MHz
#echo 450 | sudo tee /sys/class/drm/card0/gt_min_freq_mhz
#

#echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Add the flag to all installed kernel entries
#sudo grubby --update-kernel=ALL --args="i915.enable_psr=0"
#
#sudo grubby --update-kernel=ALL --args="i915.enable_psr=0 intel_pstate=no_turbo=1"
sudo grubby --update-kernel=ALL --args="i915.gt_min_freq_mhz=500 i915.gt_max_freq_mhz=800"
