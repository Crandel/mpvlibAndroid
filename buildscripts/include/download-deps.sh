#!/bin/bash -e

. ./include/depinfo.sh

[ -z "$IN_CI" ] && IN_CI=0
[ -z "$WGET" ] && WGET=wget

# Every clone is shallow: this tree is rebuilt inside a container whose disk is
# shared with four ABI build trees, and a full FFmpeg history alone is ~2 GB.
# The tradeoff is that refs must exist on the remote, and `git describe` in
# scripts/write_versions.sh sees no ancestors.
mkdir -p deps && cd deps

# mbedtls
if [ ! -d mbedtls ]; then
	mkdir mbedtls
	$WGET https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$v_mbedtls/mbedtls-$v_mbedtls.tar.bz2 -O - | \
		tar -xj -C mbedtls --strip-components=1
fi

# dav1d
if [ ! -d dav1d ]; then
	git clone --depth=1 https://github.com/videolan/dav1d
fi

# ffmpeg
if [ ! -d ffmpeg ]; then
	args=()
	[ $IN_CI -eq 1 ] && args+=(--depth=1 -b "$v_ci_ffmpeg")
	git clone https://github.com/FFmpeg/FFmpeg ffmpeg "${args[@]}"
fi

# freetype2
if [ ! -d freetype2 ]; then
	git clone --depth=1 --recurse-submodules --shallow-submodules \
		https://gitlab.freedesktop.org/freetype/freetype.git freetype2 \
		-b VER-${v_freetype//./-}
fi

# fribidi
if [ ! -d fribidi ]; then
	mkdir fribidi
	$WGET https://github.com/fribidi/fribidi/releases/download/v$v_fribidi/fribidi-$v_fribidi.tar.xz -O - | \
		tar -xJ -C fribidi --strip-components=1
fi

# harfbuzz
if [ ! -d harfbuzz ]; then
	mkdir harfbuzz
	$WGET https://github.com/harfbuzz/harfbuzz/releases/download/$v_harfbuzz/harfbuzz-$v_harfbuzz.tar.xz -O - | \
		tar -xJ -C harfbuzz --strip-components=1
fi

# unibreak
if [ ! -d unibreak ]; then
	mkdir unibreak
	$WGET https://github.com/adah1972/libunibreak/releases/download/libunibreak_${v_unibreak//./_}/libunibreak-${v_unibreak}.tar.gz -O - | \
		tar -xz -C unibreak --strip-components=1
fi

# libxml2
if [ ! -d libxml2 ]; then
	mkdir libxml2
	$WGET https://gitlab.gnome.org/GNOME/libxml2/-/archive/v${v_libxml2}/libxml2-v${v_libxml2}.tar.gz -O - | \
		tar -xz -C libxml2 --strip-components=1
fi

# fontconfig
if [ ! -d fontconfig ]; then
	mkdir fontconfig
	$WGET https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/${v_fontconfig}/fontconfig-${v_fontconfig}.tar.gz -O - | \
		tar -xz -C fontconfig --strip-components=1
fi

# libass
if [ ! -d libass ]; then
	git clone --depth=1 https://github.com/libass/libass
fi

# lua
if [ ! -d lua ]; then
	mkdir lua
	$WGET https://www.lua.org/ftp/lua-$v_lua.tar.gz -O - | \
		tar -xz -C lua --strip-components=1
fi

# shaderc
# Kept although upstream dropped it: libplacebo is built with vulkan enabled
# here, so it needs a GLSL->SPIR-V compiler (see depinfo.sh dep_libplacebo).
if [ ! -d shaderc ]; then
	mkdir -p shaderc
	cat >shaderc/README <<'HEREDOC'
shaderc sources are provided by the NDK
see <ndk>/sources/third_party/shaderc
HEREDOC
fi

# libplacebo
# Pinned rather than tracked at master: mpv >=0.42.0 requires libplacebo
# >=7.387.0, and a pinned tag keeps a rebuilt AAR bit-identical to what
# app/libs/mpv-android-lib.properties claims.
if [ ! -d libplacebo ]; then
	git clone --depth=1 --recursive --shallow-submodules \
		--branch "$v_libplacebo" https://github.com/haasn/libplacebo
fi

# curl
if [ ! -d curl ]; then
	mkdir curl
	$WGET https://curl.se/download/curl-$v_curl.tar.gz -O - | \
		tar -xz -C curl --strip-components=1
fi

# mpv
if [ ! -d mpv ]; then
	git clone --depth=1 --branch "$v_mpv" https://github.com/mpv-player/mpv
fi

cd ..
