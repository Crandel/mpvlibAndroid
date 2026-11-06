#!/bin/bash
# Android provides Vulkan but ships no pkg-config file, so both libplacebo
# (-Dvk-proc-addr=enabled) and mpv (-Dvulkan=enabled) would fail to resolve the
# dependency without this. Sourced from scripts/libplacebo.sh and scripts/mpv.sh
# while $CC and $prefix_dir are set.
#
# The headers come from the NDK sysroot and are found by the compiler on their
# own, so Cflags stays empty; only the version matters, because mpv 0.42.0 asks
# meson for dependency('vulkan', version: '>= 1.4.309'). Reading
# VK_HEADER_VERSION instead of hardcoding it keeps the file honest when the NDK
# moves, and turns an NDK that is too old into an immediate error rather than a
# meson failure deep inside the mpv configure step.

# Sourced scripts get no depinfo variables from buildall.sh (it only sources
# them in its own shell), so read the floor from here.
. "$( dirname "${BASH_SOURCE[0]}" )"/depinfo.sh

# The NDK's <triple><api>-clang wrappers reject -print-sysroot, so take the
# sysroot from ANDROID_NDK_ROOT (exported by buildall.sh loadndk).
vk_sysroot="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/${os}-x86_64/sysroot"
vk_header="$vk_sysroot/usr/include/vulkan/vulkan_core.h"
if [ ! -f "$vk_header" ]; then
	echo >&2 "No Vulkan headers under '$vk_sysroot'. Run this through buildall.sh, which exports ANDROID_NDK_ROOT."
	exit 1
fi
vk_hdr_version=$(grep -m1 -oE 'define VK_HEADER_VERSION [0-9]+' "$vk_header" | awk '{print $3}' || true)

if [ -z "$vk_hdr_version" ]; then
	echo >&2 "Could not read VK_HEADER_VERSION from $vk_header"
	exit 1
fi
if [ "$vk_hdr_version" -lt "${v_vulkan_headers_min##*.}" ]; then
	echo >&2 "Vulkan headers 1.4.$vk_hdr_version are too old: mpv requires >= $v_vulkan_headers_min."
	exit 1
fi

mkdir -p "$prefix_dir"/lib/pkgconfig
cat >"$prefix_dir"/lib/pkgconfig/vulkan.pc <<END
Name: Vulkan
Description: Vulkan headers from the Android NDK sysroot
Version: 1.4.$vk_hdr_version
Libs: -lvulkan
Cflags:
END
