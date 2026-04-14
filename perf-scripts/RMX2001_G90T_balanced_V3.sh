#!/system/bin/sh

# =============================================================
#  Balanced Mode Script V3
#  Device   : Realme 6 (RMX2001) - 8/128 UFS 2.1 variant
#  Author   : Arhan Das
#  Assisted by Claude (Anthropic)
#  Version  : V3 - Reverts all V4 OC locks, TCP fix (hybla),
#                  UFS 2.1 restore, FBT restore, charge restore
#                  touch restore, SLA disable
# =============================================================

# -------------------------------------------------------------
# Gather device info dynamically
# -------------------------------------------------------------
DEVICE_MODEL=$(getprop ro.product.model)
DEVICE_CODENAME=$(getprop ro.product.device)
DEVICE_BRAND=$(getprop ro.product.brand)
CHIPSET=$(getprop ro.board.platform)
ROM_NAME=$(getprop ro.build.display.id)
ANDROID_VER=$(getprop ro.build.version.release)
KERNEL_VER=$(uname -r)
RAM_TOTAL=$(cat /proc/meminfo | grep MemTotal | awk '{printf "%.0f MB", $2/1024}')

clear
echo "============================================="
echo " Balanced Mode V3"
echo "============================================="
echo " Device   : $DEVICE_BRAND $DEVICE_MODEL ($DEVICE_CODENAME)"
echo " Chipset  : $CHIPSET"
echo " Android  : $ANDROID_VER"
echo " ROM      : $ROM_NAME"
echo " Kernel   : $KERNEL_VER"
echo " RAM      : $RAM_TOTAL"
echo "============================================="
echo " Author   : Arhan Das | Assisted by Claude"
echo "============================================="
echo " Reverting High Performance mode..."
echo " Optimised for smooth daily use + battery"
echo "============================================="
echo

# -------------------------------------------------------------
# restore_val() - chmod 644 to bypass 444 locks, then write
# -------------------------------------------------------------
restore_val() {
    if [ -f "$2" ]; then
        chmod 644 "$2" >/dev/null 2>&1
        echo "$1" > "$2" 2>/dev/null
    fi
}

# -------------------------------------------------------------
# STEP 1: Restore charging FIRST
# -------------------------------------------------------------
echo "Restoring battery charging"
echo 0 > /proc/charger/stop_charging_enable 2>/dev/null
echo 1 > /proc/charger/mmi_charging_enable 2>/dev/null
echo "Charging restored"
echo

# -------------------------------------------------------------
# STEP 2: Unlock thermal message FIRST before thermal daemon
# -------------------------------------------------------------
echo "Unlocking thermal limits"
chmod 644 /sys/devices/virtual/thermal/thermal_message/cpu_limits 2>/dev/null
for path in /sys/devices/system/cpu/*/cpufreq; do
    cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
    cpu_minfreq=$(cat $path/cpuinfo_min_freq)
    echo "cpu$(awk '{print $1}' $path/affected_cpus) $cpu_maxfreq" > /sys/devices/virtual/thermal/thermal_message/cpu_limits 2>/dev/null
    restore_val "$cpu_maxfreq" $path/scaling_max_freq
    restore_val "$cpu_minfreq" $path/scaling_min_freq
done
echo "Thermal limits restored"
echo

# -------------------------------------------------------------
# STEP 3: Restart thermal daemon
# -------------------------------------------------------------
echo "Restarting thermal daemon"
start thermal
echo

# -------------------------------------------------------------
# Restore battery OC throttle
# -------------------------------------------------------------
echo "Restoring battery OC protection"
restore_val "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop
echo

# -------------------------------------------------------------
# Power settings
# -------------------------------------------------------------
settings put global low_power 0
settings put secure high_priority 0
settings put secure low_priority 1

# -------------------------------------------------------------
# GED Modules - balanced values
# -------------------------------------------------------------
echo "Configuring GED Modules for balanced mode"
restore_val 0 /sys/module/ged/parameters/gx_game_mode
restore_val 0 /sys/module/ged/parameters/gx_force_cpu_boost
restore_val 0 /sys/module/ged/parameters/boost_amp
restore_val 0 /sys/module/ged/parameters/boost_extra
restore_val 0 /sys/module/ged/parameters/boost_gpu_enable
restore_val 1 /sys/module/ged/parameters/enable_cpu_boost
restore_val 1 /sys/module/ged/parameters/enable_gpu_boost
restore_val 0 /sys/module/ged/parameters/enable_game_self_frc_detect
restore_val 50 /sys/module/ged/parameters/gpu_idle
restore_val 0 /sys/module/ged/parameters/cpu_boost_policy
restore_val 0 /sys/module/ged/parameters/ged_force_mdp_enable
restore_val 1 /sys/module/ged/parameters/ged_boost_enable
restore_val 50 /sys/module/ged/parameters/ged_smart_boost
restore_val 0 /sys/module/ged/parameters/gx_frc_mode
restore_val 0 /sys/module/ged/parameters/gx_boost_on
restore_val 0 /sys/module/ged/parameters/gx_3D_benchmark_on
restore_val 0 /sys/module/ged/parameters/gpu_loading
restore_val 0 /sys/module/ged/parameters/boost_upper_bound
restore_val 1 /sys/module/ged/parameters/gpu_dvfs_enable
restore_val 0 /sys/module/ged/parameters/g_gpu_timer_based_emu
restore_val 1 /sys/module/ged/parameters/ged_monitor_3D_fence_disable
restore_val 0 /sys/module/ged/parameters/gpu_cust_boost_freq
restore_val 0 /sys/module/ged/parameters/gpu_cust_upbound_freq
restore_val 0 /sys/module/ged/parameters/gpu_bottom_freq
restore_val 60 /sys/module/ged/parameters/gx_dfps
echo "GED Modules restored"
echo

# -------------------------------------------------------------
# Revert FPSGO to defaults
# -------------------------------------------------------------
echo "Reverting FPSGO to defaults"
for fpsgo in /sys/kernel/fpsgo; do
    restore_val 0 $fpsgo/fbt/boost_ta
    restore_val 1 $fpsgo/fbt/enable_switch_down_throttle
    restore_val 1 $fpsgo/fstb/adopt_low_fps
    restore_val 1 $fpsgo/fstb/fstb_self_ctrl_fps_enable
    restore_val 1 $fpsgo/fstb/enable_switch_sync_flag
    restore_val 0 $fpsgo/fbt/boost_VIP
    restore_val 1 $fpsgo/fstb/gpu_slowdown_check
    restore_val 1 $fpsgo/fbt/thrm_limit_cpu
    restore_val 80 $fpsgo/fbt/thrm_temp_th
    restore_val 0 $fpsgo/fbt/llf_task_policy
done
restore_val 0 /sys/kernel/ged/hal/gpu_boost_level
for fpsgo_adv in /sys/module/mtk_fpsgo/parameters; do
    restore_val 0 $fpsgo_adv/boost_affinity
    restore_val 0 $fpsgo_adv/boost_LR
    restore_val 0 $fpsgo_adv/xgf_uboost
    restore_val 0 $fpsgo_adv/xgf_extra_sub
    restore_val 0 $fpsgo_adv/gcc_enable
    restore_val 0 $fpsgo_adv/gcc_hwui_hint
done
echo "FPSGO reverted"
echo

# -------------------------------------------------------------
# Revert FBT Frame Buffer Tuner to defaults
# -------------------------------------------------------------
echo "Reverting FBT to balanced defaults"
for fbt in /sys/module/fbt_cpu/parameters; do
    restore_val 50  $fbt/rescue_percent
    restore_val 50  $fbt/rescue_percent_90
    restore_val 50  $fbt/rescue_percent_120
    restore_val 1   $fbt/adjust_loading
    restore_val 3   $fbt/floor_bound
    restore_val 5   $fbt/bhr
    restore_val 16  $fbt/sampling_period_MS
    restore_val 1   $fbt/check_running
    restore_val 1   $fbt/variance
done
echo "FBT restored"
echo

# -------------------------------------------------------------
# CPU Mode - balanced
# -------------------------------------------------------------
echo "CPU Mode"
restore_val 1 /proc/cpufreq/cpufreq_power_mode
cat /proc/cpufreq/cpufreq_power_mode
restore_val 0 /proc/cpufreq/cpufreq_cci_mode
cat /proc/cpufreq/cpufreq_cci_mode
restore_val 0 /proc/cpufreq/cpufreq_sched_disable
echo

# -------------------------------------------------------------
# Kernel Scheduler - restore balanced values
# -------------------------------------------------------------
echo "Restoring kernel scheduler"
restore_val 1 /proc/sys/kernel/sched_autogroup_enabled
restore_val 0 /proc/sys/kernel/sched_child_runs_first
restore_val 25 /proc/sys/kernel/perf_cpu_time_max_percent
restore_val 1 /proc/sys/kernel/sched_cstate_aware
restore_val 500000 /proc/sys/kernel/sched_migration_cost_ns
restore_val 750000 /proc/sys/kernel/sched_min_granularity_ns
restore_val 1000000 /proc/sys/kernel/sched_wakeup_granularity_ns
restore_val 1 /proc/sys/kernel/timer_migration
restore_val 15 /proc/sys/kernel/sched_min_task_util_for_colocation
restore_val 0 /proc/sys/kernel/sched_sync_hint_enable
# WALT - restore
restore_val 0 /proc/sys/kernel/sched_use_walt_cpu_util 2>/dev/null
restore_val 0 /proc/sys/kernel/sched_use_walt_task_util 2>/dev/null
# Restore printk
restore_val "7 4 1 7" /proc/sys/kernel/printk
restore_val on /proc/sys/kernel/printk_devkmsg
if [ -f "/sys/kernel/debug/sched_features" ]; then
    restore_val NEXT_BUDDY /sys/kernel/debug/sched_features
    restore_val TTWU_QUEUE /sys/kernel/debug/sched_features
fi
echo "Scheduler restored"
echo

# -------------------------------------------------------------
# EAS - re-enable mode 1
# -------------------------------------------------------------
echo "Kernel Mode - EAS balanced"
restore_val 1 /sys/devices/system/cpu/eas/enable
cat /sys/devices/system/cpu/eas/enable
echo

# -------------------------------------------------------------
# Scheduler I/O - UFS 2.1 balanced
# -------------------------------------------------------------
echo "Scheduler I/O"
if [ -b /dev/sda ]; then
    restore_val mq-deadline /sys/block/sda/queue/scheduler 2>/dev/null
    restore_val 128 /sys/block/sda/queue/read_ahead_kb
    restore_val 2 /sys/block/sda/queue/rq_affinity
    restore_val 0 /sys/block/sda/queue/add_random
    restore_val 0 /sys/block/sda/queue/nomerges
    echo "UFS 2.1 storage restored to balanced (sda)"
    cat /sys/block/sda/queue/scheduler
fi
if [ -b /dev/mmcblk0 ]; then
    restore_val mq-deadline /sys/block/mmcblk0/queue/scheduler 2>/dev/null
    restore_val 128 /sys/block/mmcblk0/queue/read_ahead_kb
fi
for path in /sys/class/devfreq/*.ufshc; do
    restore_val simple_ondemand $path/governor 2>/dev/null
done
echo

# -------------------------------------------------------------
# CPU Performance node - off for battery
# -------------------------------------------------------------
echo "Performance"
restore_val 0 /sys/devices/system/cpu/perf/enable
restore_val 0 /sys/devices/system/cpu/perf/gpu_pmu_enable 2>/dev/null
cat /sys/devices/system/cpu/perf/enable
echo

# -------------------------------------------------------------
# GPU Frequency
# Max = 3rd value in table (sensible daily cap)
# Min = 7th value (prevents UI stutter)
# -------------------------------------------------------------
echo "GPU Frequency"
GPU_FREQ_TABLE=$(cat /sys/kernel/gpu/gpu_freq_table)
GPU_MAX=$(echo $GPU_FREQ_TABLE | awk '{print $3}')
GPU_MIN=$(echo $GPU_FREQ_TABLE | awk '{print $7}')
echo "Detected GPU freq table: $GPU_FREQ_TABLE"
echo "Setting GPU max to ${GPU_MAX}MHz (3rd value)"
echo "Setting GPU min to ${GPU_MIN}MHz (7th value)"
restore_val 0 /proc/gpufreq/gpufreq_opp_freq
restore_val $GPU_MAX /sys/kernel/gpu/gpu_max_clock
restore_val $GPU_MIN /sys/kernel/gpu/gpu_min_clock
echo "GPU max: $(cat /sys/kernel/gpu/gpu_max_clock) MHz"
echo "GPU min: $(cat /sys/kernel/gpu/gpu_min_clock) MHz"
echo

# -------------------------------------------------------------
# GPU Thermal - restore limits
# -------------------------------------------------------------
echo "Restoring GPU thermal limits"
restore_val 0 /proc/gpufreq/gpufreq_limited_thermal_ignore
restore_val 0 /proc/gpufreq/gpufreq_limited_oc_ignore
restore_val 0 /proc/gpufreq/gpufreq_limited_low_batt_volume_ignore
restore_val 0 /proc/gpufreq/gpufreq_limited_low_batt_volt_ignore
restore_val 1 /proc/gpufreq/gpufreq_power_limited
echo "GPU thermal limits restored"
echo

# -------------------------------------------------------------
# GPU Power Policy - coarse_demand for daily use
# -------------------------------------------------------------
echo "GPU Power Policy"
restore_val 0 /proc/mali/always_on
cat /proc/mali/always_on
restore_val coarse_demand /sys/devices/platform/13040000.mali/power_policy
cat /sys/devices/platform/13040000.mali/power_policy
restore_val coarse_demand /sys/class/misc/mali0/device/power_policy
echo

# -------------------------------------------------------------
# DRAM - restore to userspace/auto
# -------------------------------------------------------------
echo "Restoring DRAM governor"
restore_val -1 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
restore_val 0 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode
restore_val userspace /sys/class/devfreq/mtk-dvfsrc-devfreq/governor
restore_val userspace /sys/devices/platform/soc/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor
for path in /sys/class/devfreq/mmc*; do
    restore_val simple_ondemand $path/governor
done
echo "DRAM restored"
echo

# -------------------------------------------------------------
# PPM - balanced policies
# -------------------------------------------------------------
echo "PPM:"
restore_val 1 /proc/ppm/enabled
echo "0 1" > /proc/ppm/policy_status
echo "1 1" > /proc/ppm/policy_status
echo "2 1" > /proc/ppm/policy_status
echo "3 0" > /proc/ppm/policy_status
echo "4 0" > /proc/ppm/policy_status
echo "5 1" > /proc/ppm/policy_status
echo "6 1" > /proc/ppm/policy_status
echo "7 1" > /proc/ppm/policy_status
echo "8 0" > /proc/ppm/policy_status
echo "9 1" > /proc/ppm/policy_status
cat /proc/ppm/policy_status
echo

# -------------------------------------------------------------
# Governor - schedutil
# -------------------------------------------------------------
echo "Governor:"
for path in /sys/devices/system/cpu/cpufreq/policy*; do
    restore_val schedutil "$path/scaling_governor"
done
cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
echo

# -------------------------------------------------------------
# CPU Frequency - unlock for smart scaling
# -------------------------------------------------------------
echo "CPU Frequency - unlocked for smart scaling"
cluster=0
for path in /sys/devices/system/cpu/cpufreq/policy*; do
    cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
    cpu_minfreq=$(cat $path/cpuinfo_min_freq)
    restore_val "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
    restore_val "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
    cluster=$((cluster + 1))
done
echo "Clusters unlocked for dynamic scaling"
echo

# -------------------------------------------------------------
# Game state off
# -------------------------------------------------------------
restore_val 0 /proc/game_state 2>/dev/null
restore_val 1 /proc/trans_scheduler/enable 2>/dev/null

# -------------------------------------------------------------
# HyperEngine Network Engine - disable for daily use
# -------------------------------------------------------------
restore_val 0 /proc/sys/net/oplus_sla/sla_enable 2>/dev/null

# -------------------------------------------------------------
# Touch - restore to balanced (keep game sampling for
# responsiveness, restore sensitivity to default)
# -------------------------------------------------------------
echo "Touch settings restored"
restore_val 1 /proc/touchpanel/game_switch_enable
restore_val 1 /proc/touchpanel/oplus_tp_direction
restore_val 0 /proc/touchpanel/oplus_tp_limit_enable
restore_val 2 /proc/touchpanel/smooth_level      # Default balanced smoothing
restore_val 3 /proc/touchpanel/sensitive_level   # Default sensitivity
echo

# -------------------------------------------------------------
# CABC - keep off
# -------------------------------------------------------------
echo "Disable CABC"
restore_val 0 /sys/kernel/oppo_display/LCM_CABC
echo

# -------------------------------------------------------------
# Re-enable debugging
# -------------------------------------------------------------
restore_val 1 /sys/kernel/ccci/debug
restore_val 1 /sys/kernel/tracing/tracing_on
restore_val "7 4 1 7" /proc/sys/kernel/printk
restore_val on /proc/sys/kernel/printk_devkmsg

# -------------------------------------------------------------
# Logcat
# -------------------------------------------------------------
echo "Force stop logcat to reduce CPU hogging"
stop logd
echo

# -------------------------------------------------------------
# TCP - hybla is better for daily mobile use
# (westwood NOT compiled in Miku kernel - hybla confirmed in)
# -------------------------------------------------------------
echo "TCP Network"
restore_val hybla /proc/sys/net/ipv4/tcp_congestion_control
cat /proc/sys/net/ipv4/tcp_congestion_control
restore_val 1 /proc/sys/net/ipv4/tcp_low_latency
# Restore default buffer sizes
restore_val "4096 87380 6291456" /proc/sys/net/ipv4/tcp_rmem
restore_val "4096 16384 4194304" /proc/sys/net/ipv4/tcp_wmem
echo "TCP restored to hybla (mobile optimised)"
echo

# -------------------------------------------------------------
# VM - balanced memory management
# -------------------------------------------------------------
echo "VM Tweaks"
restore_val 1 /proc/sys/vm/drop_caches
restore_val 40 /proc/sys/vm/swappiness
cat /proc/sys/vm/swappiness
restore_val 20 /proc/sys/vm/dirty_ratio
restore_val 10 /proc/sys/vm/dirty_background_ratio
restore_val 1500 /proc/sys/vm/dirty_writeback_centisecs
restore_val 100 /proc/sys/vm/vfs_cache_pressure
restore_val 20 /proc/sys/vm/compaction_proactiveness
restore_val 3 /proc/sys/vm/page-cluster
restore_val 0 /proc/sys/vm/overcommit_memory
# THP - madvise for balanced
restore_val madvise /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null
restore_val madvise /sys/kernel/mm/transparent_hugepage/shmem_enabled 2>/dev/null
echo "VM tweaks applied"
echo

# -------------------------------------------------------------
# CPUSet / SchedTune - balanced
# -------------------------------------------------------------
echo "Modify CPUStune"
restore_val 0-7 /dev/cpuset/foreground/cpus
restore_val 0-3 /dev/cpuset/background/cpus
restore_val 0-5 /dev/cpuset/system-background/cpus
restore_val 0-7 /dev/cpuset/top-app/cpus
restore_val 0-1 /dev/cpuset/restricted/cpus
restore_val 1 /dev/cpuset/sched_load_balance 2>/dev/null
restore_val 1 /dev/cpuset/foreground/sched_load_balance 2>/dev/null

# Realtime
restore_val 0 /dev/stune/rt/schedtune.boost
restore_val 1 /dev/stune/rt/schedtune.prefer_idle

# Background
restore_val 0 /dev/stune/background/schedtune.util.max.effective
restore_val 0 /dev/stune/background/schedtune.util.min.effective
restore_val 200 /dev/stune/background/schedtune.util.max
restore_val 0 /dev/stune/background/schedtune.util.min
restore_val 0 /dev/stune/background/schedtune.boost
restore_val 0 /dev/stune/background/schedtune.prefer_idle

# Foreground
restore_val 1024 /dev/stune/foreground/schedtune.util.max.effective
restore_val 0 /dev/stune/foreground/schedtune.util.min.effective
restore_val 1024 /dev/stune/foreground/schedtune.util.max
restore_val 0 /dev/stune/foreground/schedtune.util.min
restore_val 0 /dev/stune/foreground/schedtune.boost
restore_val 1 /dev/stune/foreground/schedtune.prefer_idle

# Top-App
restore_val 1024 /dev/stune/top-app/schedtune.util.max.effective
restore_val 0 /dev/stune/top-app/schedtune.util.min.effective
restore_val 1024 /dev/stune/top-app/schedtune.util.max
restore_val 0 /dev/stune/top-app/schedtune.util.min
restore_val 0 /dev/stune/top-app/schedtune.boost
restore_val 1 /dev/stune/top-app/schedtune.prefer_idle

# Global
restore_val 0 /dev/stune/schedtune.util.min
restore_val 1024 /dev/stune/schedtune.util.max
restore_val 1024 /dev/stune/schedtune.util.max.effective
restore_val 0 /dev/stune/schedtune.util.min.effective
restore_val 0 /dev/stune/schedtune.boost
restore_val 1 /dev/stune/schedtune.prefer_idle
echo

echo "============================================="
echo " Balanced Mode V3 is ACTIVE"
echo " Charging: RESTORED"
echo " TCP: hybla (mobile optimised)"
echo " Touch: smooth=2, sensitive=3 (default)"
echo " Storage: UFS 2.1 balanced"
echo " Device optimised for smooth daily use"
echo " Author   : Arhan Das | Assisted by Claude"
echo "============================================="
echo
