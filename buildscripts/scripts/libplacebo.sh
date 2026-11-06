#!/bin/bash -e

. ../../include/path.sh

build=_build$ndk_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf $build
	exit 0
else
	exit 255
fi

# Vulkan stays enabled here, unlike upstream mpv-android, which passes
# -Dvulkan=disabled and therefore ships an OpenGL-only libmpv.
# -Dvk-proc-addr=enabled is a hard requirement: without it the vulkan.pc
# dependency resolves to NO and meson fails with "Feature vk-proc-addr cannot
# be enabled". libplacebo is built *before* mpv
# (dep_mpv=(ffmpeg libass lua libplacebo curl)), so it has to write vulkan.pc
# itself rather than rely on scripts/mpv.sh.
. ../../include/vulkan_pc.sh

unset CC CXX
meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	-Dvulkan=enabled -Dvk-proc-addr=enabled -Ddemos=false

ninja -C $build -j$cores
DESTDIR="$prefix_dir" ninja -C $build install

# add missing library for static linking
# this isn't "-lstdc++" due to a meson bug: https://github.com/mesonbuild/meson/issues/11300
${SED:-sed} '/^Libs:/ s|$| -lc++|' "$prefix_dir/lib/pkgconfig/libplacebo.pc" -i
