# GL-MT3600BE custom build result

Build completed on 2026-10-06. The sysupgrade image was subsequently
installed on a GL-MT3600BE and booted successfully.

## Firmware

| Item | Value |
|---|---|
| Target | `mediatek/filogic` |
| Profile | `glinet_gl-mt3600be` |
| OpenWrt | `25.12-SNAPSHOT` / `r0+32742-7e35c47c00` |
| Kernel | `6.12.74` |
| sysupgrade size | `15,626,525` bytes |
| sysupgrade SHA-256 | `250186132ffa714d0259cae72fcd7852282f6c2796580bc82d6ce0900dddce86` |
| initramfs size | `15,009,960` bytes |
| initramfs SHA-256 | `9fdebcf0a39583e0c07319108963b88d43b571c528cc0d330c0f915e4f90d76b` |

The deployable image is:

`output/openwrt-mediatek-filogic-glinet_gl-mt3600be-squashfs-sysupgrade.bin`

## Validation performed

- Every entry in OpenWrt's `sha256sums` passes.
- `profiles.json` contains only `glinet_gl-mt3600be`, with supported device `glinet,gl-mt3600be`.
- The sysupgrade archive contains `CONTROL`, `kernel`, and `root`; `CONTROL` identifies `BOARD=glinet_gl-mt3600be`.
- Embedded firmware metadata identifies OpenWrt `25.12-SNAPSHOT`, target `mediatek/filogic`, and board `glinet_gl-mt3600be`.
- The SquashFS contains the MediaTek public-feed `mt76/mac80211` stack, including `mt7996e.ko`, MT7990 firmware, and `mt7996e wed_enable=1` autoload configuration.
- The SquashFS contains `mtk-2p5ge.ko` and the official MT7987 2.5GbE PHY firmware. Firmware SHA-256 values are:
  - `i2p5ge-phy-DSPBitTb.bin`: `1f7b7fd1c243576e04c16b98c649db1e3326f6a715556c2a56094bcd7d300d71`
  - `i2p5ge-phy-pmb.bin`: `941e3118493d5cb14323968ebc1193b23411d7c330a566014eeeb51c5ea7ed45`
- The internal MediaTek PHY firmware package is absent.
- LuCI, `relayd`, USB storage, ext4/VFAT support, and USB diagnostic tools are present.
- `mt_wifi7.ko` is intentionally absent; this build uses MediaTek's public-feed-enhanced `mt76/mac80211` driver stack, not the closed SDK driver.

## Hardware validation performed

- The sysupgrade image boots on a GL.iNET GL-MT3600BE.
- Ethernet LAN access, SSH authentication, and LuCI login work.
- `apk update` works after removing the build-only `mtk_openwrt_feed` entry described below.
- The official Japanese LuCI translation packages can be installed and selected.

Wi-Fi 7 modes, 2.5GbE stability, hardware offload, USB, thermals, power
consumption, and sustained performance have not yet been exhaustively tested.

## Known issue in this image

The image contains a repository entry for the local build feed
`mtk_openwrt_feed`. That feed is not published by downloads.openwrt.org, so it
must be removed once after installation:

```sh
cp -p /etc/apk/repositories.d/distfeeds.list /root/distfeeds.list.bak
sed -i '/mtk_openwrt_feed/d' /etc/apk/repositories.d/distfeeds.list
apk update
```

This does not remove any installed MediaTek driver or package. Do not run a
blanket `apk upgrade`, and do not force-install official snapshot `kmod-*`
packages over this custom kernel.

OpenWrt's target-level `openwrt-mediatek-filogic.manifest` describes the common rootfs. The four per-device additions are recorded in `profiles.json`; extraction of the image's APK database additionally confirmed `kmod-mt7990-firmware`, `kmod-mt7996e`, `kmod-hwmon-pwmfan`, and `kmod-usb3` in the actual Beryl 7 rootfs.

## Safety status

This image is a custom, partially hardware-tested build. It is neither an OpenWrt official release image nor GL.iNet firmware. It contains no GL.iNet UI or proprietary services. Use only the sysupgrade image for the matching GL-MT3600BE board, preserve recovery access and calibration/MTD backups, and do not treat it as a factory or bootloader image.
