# Upstream software and licensing notice

This repository contains a build recipe, configuration seed, documentation,
and a small integration patch. It does not vendor the OpenWrt or MediaTek
source trees. The build helper obtains source from the following upstream
projects at the revisions recorded in `README.md`:

- OpenWrt: <https://github.com/openwrt/openwrt>
- MediaTek public OpenWrt feed: <https://github.com/mediatek/mtk-openwrt-feeds>
- OpenWrt packages: <https://github.com/openwrt/packages>
- LuCI: <https://github.com/openwrt/luci>
- OpenWrt routing feed: <https://github.com/openwrt/routing>

Those projects, the Linux kernel, firmware blobs, packages, and generated
binary images are covered by their own copyright notices and licenses. Nothing
in this repository relicenses third-party code.

The GitHub Release binaries correspond to the pinned source revisions,
configuration, and patch published in the tagged repository state. The helper
can retrieve and prepare those sources. A build is source-pinned but is not
claimed to be bit-for-bit reproducible across different hosts because build
tools, generated signing keys, timestamps, and upstream download archives may
differ.

GL.iNet and Beryl are trademarks of their respective owner. This project is
not affiliated with or endorsed by GL.iNet, OpenWrt, or MediaTek.
