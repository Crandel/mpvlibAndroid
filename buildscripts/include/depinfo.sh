#!/bin/bash -e

## Dependency versions
# Make sure to keep v_ndk and v_ndk_n in sync, both are listed on the NDK download page

v_sdk=11076708_latest
v_ndk=r30
v_ndk_n=30.0.16248370
v_sdk_platform=36
v_sdk_build_tools=36.0.0

v_lua=5.2.4
v_unibreak=8.0
v_harfbuzz=15.0.0
v_fribidi=1.0.17
v_freetype=2.15.0
v_mbedtls=3.6.7
v_libxml2=2.15.4
v_fontconfig=2.18.3
v_curl=8.23.0

## Upstream sources this AAR is built from
# Overridable from the environment so a refresh can repin without an edit, e.g.
# `v_mpv=v0.42.0 ./include/download-deps.sh`. Shallow clones require the ref to
# be a branch or tag name, not a raw commit hash.
v_mpv=${MPV_REF:-${v_mpv:-master}}
v_libplacebo=${LIBPLACEBO_REF:-${v_libplacebo:-v7.387.0}}

# mpv 0.42.0 onwards rejects older Vulkan headers when -Dvulkan=enabled
# (meson: dependency('vulkan', version: '>= 1.4.309')). The NDK sysroot provides
# the headers; include/vulkan_pc.sh reads the actual version and enforces this
# floor before libplacebo/mpv are configured.
v_vulkan_headers_min=1.4.309

## Dependency tree
# I would've used a dict but putting arrays in a dict is not a thing

dep_mbedtls=()
dep_dav1d=()
dep_libxml2=()
dep_ffmpeg=(mbedtls dav1d libxml2)
dep_freetype2=()
dep_fontconfig=(libxml2 freetype2)
dep_fribidi=()
dep_harfbuzz=()
dep_unibreak=()
dep_libass=(freetype2 fontconfig fribidi harfbuzz unibreak)
dep_lua=()
# shaderc stays: this fork builds libplacebo with vulkan enabled, unlike upstream
# which disables it and therefore dropped the GLSL->SPIR-V compiler.
dep_shaderc=()
dep_libplacebo=(shaderc)
dep_curl=(mbedtls)
dep_mpv=(ffmpeg libass lua libplacebo curl)
dep_mpv_android=(mpv)


## for CI workflow

# pinned ffmpeg revision; FFMPEG_REF (the workspace-root mpvlib:* tasks) wins
v_ci_ffmpeg=${FFMPEG_REF:-n9.0.2}

# filename used to uniquely identify a build prefix
ci_tarball="prefix-n${v_ndk}-l${v_lua}-u${v_unibreak}-h${v_harfbuzz}-fr${v_fribidi}-ft${v_freetype}-x${v_libxml2}-fo${v_fontconfig}-m${v_mbedtls}-c${v_curl}-ff${v_ci_ffmpeg}.tgz"
