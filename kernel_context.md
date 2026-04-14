# Kernel Development Context — Realme 6 (RMX2001)

## Overview
This document provides full context for working on the MikuChan kernel for the Realme 6.
The goal is to fix known bugs and add performance improvements by modifying the kernel source
and compiling a new flashable kernel zip.

---

## Device Information

| Property | Value |
|---|---|
| Device | Realme 6 |
| Model | RMX2001 (also RMX2001L1, RMX2002, RMX2003, RMX2151, RMX2153, RMX2155, RMX2156, RMX2161, RMX2163) |
| Codename | nemo / RM6785 |
| SoC | MediaTek Helio G90T (MT6785) |
| CPU | 2x Cortex-A76 @ 2.05GHz + 6x Cortex-A55 @ 2.00GHz |
| GPU | Mali-G76 MC4 @ 821MHz (current kernel max) |
| RAM | 6GB / 8GB LPDDR4X |
| Storage | 64GB / 128GB UFS 2.1 |
| Display | 6.5" 1080p @ 90Hz |
| Android | 16 (Evolution X 11.5.2) |
| Root | Magisk + KernelSU |

---

## Current Kernel

| Property | Value |
|---|---|
| Name | MikuChan Kernel |
| Developer | Naveen Singh Bisht (elohim-etz) |
| Version | 4.14.366-Miku |
| Build date | Thu Feb 12 15:06:30 UTC 2026 |
| Compiler | Clang 20.0.0 |
| Compiler flags | +pgo, +bolt, +lto, +mlgo |
| KernelSU | Yes (xxKSU variant) |
| Zip filename | Miku-RM6785-xxKSU-20260212-1509.zip |

---

## Kernel Source Repositories

### Primary upstream source (community maintained, use this as base)
```
https://github.com/realme-mt6785-devs/android_kernel_realme_mt6785
Branch: lineage-22.2
```

### Miku kernel source (elohim-etz's fork)
```
https://github.com/elohim-etz/android_kernel_realme_mt6785
```

### crDroid kernel source (alternative reference)
```
https://github.com/crdroidandroid/android_kernel_realme_nemo
Branch: 16.0
```

### Evolution X device kernel source
```
https://github.com/Evolution-XYZ-Devices/kernel_realme_RMX2001
Branch: lineage-18.1
```

---

## Known Bugs to Fix

### BUG 1: 5GHz Hotspot Not Working (CRITICAL)
**Symptom:** When creating a mobile hotspot on 5GHz band, other devices cannot connect or
the hotspot fails to start on 5GHz. Falls back to 2.4GHz only.

**Likely cause:** The MT6785 WiFi driver (MediaTek in-tree driver) has a known issue with
AP mode on 5GHz channels. This is typically related to:
- Regulatory domain channel restrictions in the driver
- DFS (Dynamic Frequency Selection) not being handled correctly in AP mode
- The cfg80211/nl80211 AP mode 5GHz band configuration being incomplete

**Files to investigate:**
- `drivers/misc/mediatek/connectivity/wlan/core/div_gen4m/` — main WiFi driver
- `drivers/misc/mediatek/connectivity/wlan/core/div_gen4m/os/linux/gl_cfg80211.c` — cfg80211 interface
- `drivers/misc/mediatek/connectivity/wlan/core/div_gen4m/os/linux/gl_p2p.c` — P2P/hotspot mode
- `drivers/misc/mediatek/connectivity/wlan/core/div_gen4m/os/linux/gl_p2p_cfg80211.c` — P2P cfg80211
- Look for `CHANNEL_5G`, `IEEE80211_BAND_5GHZ`, `NL80211_IFTYPE_AP` handling

**Known fix direction:** Search XDA/GitHub for patches applied to similar MT6785/MT6785T devices
(Redmi Note 8 Pro = begonia uses same WiFi chip). The begonia community may have patches.
Also check if `CONFIG_CFG80211_REG_NOT_NEEDED` or regulatory domain settings need adjustment.

### BUG 2: WPA3 Not Working
**Symptom:** WPA3-SAE authentication fails when connecting to WPA3 networks or when
setting up a WPA3 hotspot.

**Likely cause:** WPA3/SAE (Simultaneous Authentication of Equals) support requires:
- `CONFIG_CRYPTO_LIB_CURVE25519` or SAE crypto primitives compiled in
- Proper nl80211 feature flags exposed by the driver
- `NL80211_FEATURE_SAE` flag being advertised

**Files to investigate:**
- `drivers/misc/mediatek/connectivity/wlan/core/div_gen4m/os/linux/gl_cfg80211.c`
- Look for `NL80211_FEATURE_SAE`, `WLAN_FEATURE_SAE`, `cfg80211_connect` with SAE params
- Check `net/wireless/nl80211.c` for SAE handling
- Check `crypto/` for SAE/ECC curve support

**Known fix direction:** Add `NL80211_FEATURE_SAE` to the wiphy feature flags.
May need to enable `CONFIG_CRYPTO_LIB_CURVE25519=y` in defconfig.
Check if userspace wpa_supplicant SAE offload needs kernel-side support.

---

## Performance Improvements Wanted

### 1. CPU Overclock
**Goal:** Increase CPU OPP (Operating Performance Point) table ceiling
- Big cluster (Cortex-A76): Stock 2.05GHz → Target **2.2GHz**
- Little cluster (Cortex-A55): Stock 2.00GHz → Keep at 2.00GHz (already at max)
- Community proven stable on same G90T silicon (Zenitsu kernel for Redmi Note 8 Pro/begonia)

**Files to modify:**
- `arch/arm64/boot/dts/mediatek/mt6785.dtsi` — main OPP tables
- Look for `opp-table-0` (little cluster) and `opp-table-1` (big cluster)
- Each OPP entry has `opp-hz` (frequency) and `opp-microvolt` (voltage)
- To add 2.2GHz: copy the 2.05GHz entry, increase hz to 2200000000, increase voltage slightly
  (typically +25000 to +50000 microvolts above the 2.05GHz voltage)
- Also check `arch/arm64/boot/dts/mediatek/mt6785-cpufreq.dtsi` if it exists

**Reference:** Zenitsu kernel for begonia (MT6785) achieved 2.2GHz big cores stable.
Search: `github.com search for mt6785 opp-hz 2200000000`

### 2. GPU Overclock  
**Goal:** Increase Mali-G76 MC4 frequency ceiling
- Current kernel max: 821MHz
- Target: **900MHz**
- Community proven on same G90T in Zenitsu kernel for begonia

**Files to modify:**
- `drivers/misc/mediatek/gpu/gpu_mali/mali_valhall/mali/mali_kbase/platform/mtk_platform_common/mtk_mfg_counter.c`
- `arch/arm64/boot/dts/mediatek/mt6785.dtsi` — look for GPU OPP table / `mali-gpu`
- Look for `operating-points-v2` under the Mali GPU node
- Each GPU OPP has frequency and voltage entries
- Add 850MHz and 900MHz steps with appropriate voltages

### 3. TCP Congestion Control — Add Missing Algorithms
**Current state (confirmed compiled in):**
- cubic, reno, bic, htcp, hybla, illinois, tbbr (MTK BBR variant)
- **Missing:** westwood, standard BBR (tcp_bbr)

**Goal:** Add westwood and BBR to defconfig
**Files to modify:**
- `arch/arm64/configs/mt6785_defconfig` (or similar defconfig name)
- Add: `CONFIG_TCP_CONG_WESTWOOD=y`
- Add: `CONFIG_TCP_CONG_BBR=y`
- These are standard kernel features, just need enabling in defconfig

### 4. Touch Panel — Higher Sampling Rate
**Current state:**
- Touch driver: Synaptics TCM (syna-tcm)
- Confirmed rates: 120Hz normal, 180Hz game mode
- Driver: `drivers/input/touchscreen/oplus_touchscreen/Synaptics/synaptics_tcm_core.c`

**Goal:** Investigate if 240Hz or higher is possible on this hardware
- Check `report_rate_game_value` in the Synaptics TCM driver
- The string `0x01:120HZ, 0x02:180HZ` in the binary suggests only two modes
- If hardware supports higher, add 0x03 or 0x04 mode

**Files to investigate:**
- `drivers/input/touchscreen/oplus_touchscreen/Synaptics/synaptics_tcm_core.c`
- `drivers/input/touchscreen/oplus_touchscreen/Synaptics/synaptics_tcm_touch.c`
- Look for `syna_tcm_set_game_mode` and `report_rate_game_value`

### 5. IO Scheduler — Add Kyber
**Goal:** Add Kyber IO scheduler (better than deadline for eMMC low latency)
**File:** defconfig — Add `CONFIG_MQ_IOSCHED_KYBER=y`
Kyber is already confirmed compiled in via binary analysis, just needs enabling if not in defconfig.

### 6. ZRAM Compression — Add Zstd
**Goal:** Add zstd as ZRAM compression algorithm option (better ratio than lz4)
**File:** defconfig — Verify `CONFIG_ZRAM_DEF_COMP_ZSTD` or ensure zstd module available
Zstd strings confirmed in kernel binary.

---

## Kernel Configuration (Defconfig)

The defconfig file is likely at one of:
- `arch/arm64/configs/mt6785_defconfig`
- `arch/arm64/configs/RM6785_defconfig`
- Check the build scripts / `OplusKernelEnvConfig.mk` for the exact defconfig name

Key things to verify are enabled in defconfig:
```
CONFIG_TCP_CONG_BBR=y
CONFIG_TCP_CONG_WESTWOOD=y
CONFIG_TCP_CONG_CUBIC=y
CONFIG_TCP_CONG_BIC=y
CONFIG_TCP_CONG_HTCP=y
CONFIG_TCP_CONG_HYBLA=y
CONFIG_TCP_CONG_ILLINOIS=y
CONFIG_MQ_IOSCHED_KYBER=y
CONFIG_IOSCHED_DEADLINE=y
CONFIG_CRYPTO_LIB_CURVE25519=y  # for WPA3
CONFIG_ZRAM=y
CONFIG_ZRAM_DEF_COMP="lz4"     # can change to zstd
```

---

## Build Environment

### Recommended setup
- **OS:** Ubuntu 22.04 (via Docker on Apple Silicon Mac, or native Linux)
- **Compiler:** Clang 20.0.0 with LLD (same as original Miku build)
  - Get from: https://android.googlesource.com/toolchain/llvm-project
  - Or use Android prebuilt clang from AOSP
- **Cross compiler:** aarch64-linux-gnu-gcc (for GCC parts)
- **Build flags to match Miku:** `-O3`, LTO, PGO if possible

### Docker setup (Apple Silicon Mac)
```bash
hdiutil create -size 60g -fs "Case-sensitive APFS" -volname "kernel" ~/kernel_workspace.dmg
hdiutil attach ~/kernel_workspace.dmg
docker run -it --platform linux/amd64 \
  -v /Volumes/kernel:/workspace \
  --name kernel_build \
  ubuntu:22.04 bash

# Inside container:
apt update && apt install -y git make bc bison flex libssl-dev libelf-dev \
  python3 zip unzip curl wget gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
  clang llvm lld libncurses-dev
```

### Build commands (approximate, verify with source)
```bash
cd /workspace/kernel
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-

make O=out ARCH=arm64 mt6785_defconfig  # adjust defconfig name
make -j$(nproc) O=out ARCH=arm64 \
  CC=clang \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CLANG_TRIPLE=aarch64-linux-gnu- \
  LD=ld.lld \
  AR=llvm-ar \
  NM=llvm-nm \
  OBJCOPY=llvm-objcopy \
  OBJDUMP=llvm-objdump \
  STRIP=llvm-strip
```

### Packaging
After build, use AnyKernel3 to package:
- Copy `out/arch/arm64/boot/Image.gz` into AnyKernel3 zip
- Update `anykernel.sh` with device names (RMX2001, etc.)
- Zip and flash via TWRP or KernelSU

---

## What's Already Confirmed Working in Current Kernel

Based on binary analysis of `Miku-RM6785-xxKSU-20260212-1509.zip`:

### Confirmed present and working:
- WALT (Window Assisted Load Tracking) scheduler
- SchedTune + uclamp
- FPSGO (Frame Performance Go engine)
- Helio DVFSRC (Dynamic Voltage and Frequency Scaling)
- GED (GPU Engine Driver) with full parameter exposure
- Mali-G76 Kbase driver with js_ctx_scheduling_mode
- Synaptics TCM touch driver with game mode (180Hz)
- smooth_level and sensitive_level touch tuning
- ZRAM with LZ4 and LZO compression
- zstd compression (confirmed in binary)
- IO schedulers: deadline, mq-deadline, kyber, noop, cfq
- TCP: cubic, reno, bic, htcp, hybla, illinois, tbbr
- HMP (Heterogeneous Multi-Processing)
- CCI (Cache Coherent Interconnect) performance mode
- Battery OC throttle control (/proc/mtk_batoc_throttling/)
- Full PPM (Power Policy Manager) exposure

### Confirmed NOT present:
- TCP westwood (not compiled in)
- TCP BBR standard (tbbr is MTK variant, not upstream BBR)
- Standard BBR2

---

## Runtime Tunable Paths (Confirmed via ADB)

```
# CPU
/sys/devices/system/cpu/cpufreq/policy0/   # Little cluster (0-5)
/sys/devices/system/cpu/cpufreq/policy6/   # Big cluster (6-7)
/proc/ppm/policy/hard_userlimit_max_cpu_freq
/proc/ppm/policy/hard_userlimit_min_cpu_freq
/proc/cpufreq/cpufreq_power_mode
/proc/cpufreq/cpufreq_cci_mode

# GPU
/sys/kernel/gpu/gpu_freq_table     # Full freq table (821 806 792 ... 270)
/sys/kernel/gpu/gpu_max_clock      # Currently 821MHz ceiling
/sys/kernel/gpu/gpu_min_clock
/sys/kernel/gpu/gpu_governor       # Only "Default" available
/proc/gpufreq/gpufreq_opp_freq
/proc/gpufreq/gpufreq_limited_thermal_ignore
/proc/gpufreq/gpufreq_limited_oc_ignore

# GED/FPSGO
/sys/module/ged/parameters/*
/sys/kernel/fpsgo/*
/sys/module/mtk_fpsgo/parameters/*

# Touch
/proc/touchpanel/game_switch_enable
/proc/touchpanel/smooth_level
/proc/touchpanel/sensitive_level
/proc/touchpanel/oplus_tp_direction
/proc/touchpanel/oplus_tp_limit_enable

# Thermal
/sys/devices/virtual/thermal/thermal_message/cpu_limits
/sys/class/thermal/thermal_zone*

# DRAM
/sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
/sys/class/devfreq/mtk-dvfsrc-devfreq/governor

# Mali GPU power
/sys/devices/platform/13040000.mali/power_policy
/sys/class/misc/mali0/device/power_policy
/sys/class/misc/mali0/device/js_ctx_scheduling_mode
```

---

## Performance Scripts (Already Written)

Three shell scripts are already written and tested for runtime tuning:

1. **High Performance / OC Script V3.2** — for gaming
   - Locks CPU to max freq, enables all GED/FPSGO/DRAM performance modes
   - Stops thermal daemon, locks thermal message with chmod 000
   - GPU set to kernel max (821MHz currently), min to 3rd table value
   - Kills background apps (excluding MiXplorer)
   - Uses `tweak()` function with chmod 444 locking to prevent Android reverting settings

2. **Balanced Script V2** — for daily use
   - Uses `restore_val()` function with chmod 644 to bypass 444 locks
   - Properly reverts ALL OC script changes including thermal message unlock
   - GPU max = 3rd value in freq table, GPU min = 7th value
   - Restores thermal daemon, battery OC protection, FPSGO defaults
   - EAS mode 1, schedutil governor

3. **Balanced Boot Script** — runs on boot via Magisk service.d

---

## Priority Order for Development

1. **Fix 5GHz hotspot** — highest priority, actual functionality bug
2. **Fix WPA3** — high priority, security/compatibility bug
3. **CPU OC to 2.2GHz** — performance improvement, proven safe on G90T
4. **GPU OC to 900MHz** — performance improvement, proven safe on G90T
5. **Add TCP westwood + BBR** — small improvement, easy defconfig change
6. **Touch rate investigation** — investigate if >180Hz possible
7. **ZRAM zstd** — memory efficiency improvement

---

## Reference Kernels for Comparison

The Redmi Note 8 Pro (codename: begonia) uses the **same MT6785 SoC** and has more
mature kernel development. Many fixes and OC patches from begonia can be ported directly.

Key begonia kernel repos to reference for patches:
- Zenitsu kernel (begonia) — achieved 2.2GHz CPU + 900MHz GPU
- Search GitHub for: `begonia kernel 2.2ghz opp`
- Search GitHub for: `mt6785 5ghz hotspot fix`
- Search GitHub for: `mt6785 wpa3 fix`

---

## Notes for Claude Code

- The kernel is Linux 4.14.x — older LTS kernel, not GKI
- MediaTek in-tree drivers are heavily modified from upstream — do not assume standard paths
- WiFi driver is NOT cfg80211 upstream — it's MediaTek's proprietary driver wrapped with cfg80211
- Always check both the MTK-specific paths AND standard Linux paths for any feature
- The device uses Android Verified Boot — kernel must be re-signed or AVB disabled (already handled by AnyKernel3 + Magisk)
- KernelSU variant (xxKSU) requires KernelSU patches to remain in the source
- When modifying OPP tables, always increase voltage alongside frequency — never add a high freq OPP with stock voltage
- The thermal limits are hardware enforced in silicon at ~90°C — software changes cannot bypass this ceiling
