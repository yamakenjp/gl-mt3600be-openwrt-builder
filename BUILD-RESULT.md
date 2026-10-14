# GL-MT3600BE `beryl7.2` build result

The reproducible GitHub Actions build completed successfully on 2026-10-15
(JST). The workflow built the firmware, verified the release contents, and
published the immutable pre-release.

| Item | Value |
|---|---|
| Public repository | `yamakenjp/gl-mt3600be-openwrt-builder` |
| Release | `v25.12-snapshot-20261015.2` |
| Release source commit | `177cd61df328851f81b59a2d4d6083d4004f4432` |
| Actions run | `38637683233` |
| Target / profile | `mediatek/filogic` / `glinet_gl-mt3600be` |
| Supported device | `glinet,gl-mt3600be` |
| OpenWrt | `25.12-SNAPSHOT` |
| Image version code | `r0+32742-7e35c47c00-beryl7.2` |
| `version.buildinfo` | `r0+32742-243f15be3c` |
| Kernel | `6.12.74`, release `1`, vermagic `0b3956d720c95a8466f6efe8d7cc7dd8` |

## Firmware images

Use the sysupgrade image for a normal update. The initramfs image is for RAM
boot, recovery, or testing and must not be written as a normal sysupgrade.

| Image | Size | SHA-256 |
|---|---:|---|
| `openwrt-mediatek-filogic-glinet_gl-mt3600be-squashfs-sysupgrade.bin` | 25,395,485 bytes | `d8451e614fceef1edda799bd41ac9f45c02672d25fc2fb95517ec6073b1c8b42` |
| `openwrt-mediatek-filogic-glinet_gl-mt3600be-initramfs-kernel.bin` | 23,778,096 bytes | `80d192f44ab95cb034a965a0a8dab4c9159aa6faee82e02f80b5418c124e36bc` |

After publication, every Release asset was downloaded again and every entry
in the published `SHA256SUMS` was independently verified successfully.

## Automated validation passed

- The build produced exactly one GL-MT3600BE sysupgrade image and one
  initramfs image; `profiles.json` contains only the Beryl 7 profile.
- Tailscale `1.102.3-r1` and its matching kernel `kmod-tun` are present. The
  Tailscale binary is present in the extracted root filesystem.
- Japanese LuCI base, firewall, and package-manager translations are built in,
  with Japanese selected by the first-boot default.
- The build-only MediaTek feed is recorded for reproducibility but is disabled
  in the installed runtime repository list, so `apk update` does not request a
  nonexistent `mtk_openwrt_feed` URL.
- USB block automount has both `anon_mount=1` and `auto_mount=1`.
- The extracted root filesystem contains the required `tun`, WireGuard,
  CAKE, XFRM interface, iPhone tethering, NTFS3, exFAT, USB storage, and UAS
  kernel modules.
- The configuration includes Android RNDIS, MBIM, QMI WWAN, iPhone pairing
  tools, USB Ethernet drivers, IPsec/XFRM/VTI modules, flow offload/WED,
  EIP/Safexcel crypto acceleration, SQM/CAKE, and WireGuard tools/LuCI.
- The Beryl 7 DTS contains the requested automatic PWM fan curve: PWM
  `128/176/224/255` at `50/60/70/80` degrees C, with 5 degrees C hysteresis.
- OpenWrt target checksums and the workflow's collected-artifact checksums both
  passed. The SquashFS extraction and rootfs checks ran with sufficient
  privileges to verify device nodes as well as ordinary files.

Samba/ksmbd, HFS+, and APFS support are intentionally not included. IPsec
kernel support is included, but a user-space daemon such as strongSwan is not.

## Hardware validation status

This exact `beryl7.2` image has not yet been flashed or hardware-tested. The
preceding smaller image was successfully booted on the same GL-MT3600BE; wired
LAN, SSH, LuCI, and `apk update` were confirmed. On that running image, manual
fan testing measured approximately 3,262 RPM at PWM 128 and 5,601 RPM at PWM
255, with CPU and 2.5GbE temperatures near 55 degrees C. Those observations
were used to choose the first active step of the new curve, but the automatic
curve itself still needs post-upgrade observation.

Wi-Fi 7 modes, sustained 2.5GbE traffic, USB tethering/storage, hardware flow
offload, IPsec, thermals, power use, and long-duration stability remain to be
validated on `beryl7.2` hardware.

## Safety status

This is a custom pre-release, not an official OpenWrt or GL.iNet firmware. It
does not include the GL.iNet UI, proprietary services, or the closed
`mt_wifi7` driver; it uses the MediaTek public-feed-enhanced `mac80211`/`mt76`
stack. Use it only on a GL.iNet GL-MT3600BE, preserve backup and recovery
access, do not run blanket `apk upgrade`, and do not force-install official
snapshot `kmod-*` packages over this custom kernel ABI.
