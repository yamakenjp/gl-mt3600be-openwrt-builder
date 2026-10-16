# GL-MT3600BE `beryl7.3` build result

The source-pinned GitHub Actions build completed successfully on 2026-10-16
(JST). The workflow built the firmware, verified the release contents, and
published the immutable pre-release.

| Item | Value |
|---|---|
| Public repository | `yamakenjp/gl-mt3600be-openwrt-builder` |
| Release | `v25.12-snapshot-20261016.3` |
| Release source commit | `3adcabb25c92dfb731e27a2e583c2beb4962fda9` |
| Actions run | `38872836755` |
| Target / profile | `mediatek/filogic` / `glinet_gl-mt3600be` |
| Supported device | `glinet,gl-mt3600be` |
| OpenWrt | `25.12-SNAPSHOT` |
| Image version code | `r0+32742-7e35c47c00-beryl7.3` |
| `version.buildinfo` | `r0+32742-6a6dc2828a` |
| Kernel | `6.12.74`, release `1`, vermagic `0b3956d720c95a8466f6efe8d7cc7dd8` |

## Firmware images

Use the sysupgrade image for a normal update. The initramfs image is for RAM
boot, recovery, or testing and must not be written as a normal sysupgrade.

| Image | Size | SHA-256 |
|---|---:|---|
| `openwrt-mediatek-filogic-glinet_gl-mt3600be-squashfs-sysupgrade.bin` | 25,395,485 bytes | `5693bc7319ba50582ad6b3a953c3b555880e88d2801d7e4dfc019ed39a9f656f` |
| `openwrt-mediatek-filogic-glinet_gl-mt3600be-initramfs-kernel.bin` | 23,779,168 bytes | `a6cada2187f25827ea758b920dd001eac356c3c3d912be164383635cd1adbc1e` |

After publication, all nine Release assets were downloaded again. Every entry
in the published `SHA256SUMS` was independently verified successfully.

## Automated validation passed

- The build produced exactly one GL-MT3600BE sysupgrade image and one
  initramfs image; `profiles.json` contains only the Beryl 7 profile.
- The compiled FIT device tree has `mediatek,u3p-dis-msk=0` and references
  both the USB 2 and USB 3 PHYs. This validates the finished binary rather
  than only checking the source patch.
- The extracted root filesystem contains the executable
  `98-beryl7-usb-automount` migration. It enables `anon_mount` and
  `auto_mount` while preserving existing per-device fstab entries.
- Tailscale `1.102.3-r1` and its matching kernel `kmod-tun` are present. The
  Tailscale daemon is present in the extracted root filesystem.
- Japanese LuCI base, firewall, and package-manager translations are built in,
  with Japanese selected by the first-boot default.
- The build-only MediaTek feed is disabled in the installed runtime repository
  list, so `apk update` does not request a nonexistent feed URL.
- The root filesystem contains the required TUN, WireGuard, CAKE, XFRM,
  iPhone tethering, NTFS3, exFAT, USB storage, and UAS kernel modules.
- Android RNDIS, MBIM, QMI WWAN, iPhone pairing tools, common USB Ethernet
  drivers, IPsec/XFRM/VTI, flow offload/WED, EIP/Safexcel, SQM/CAKE, and
  WireGuard tools/LuCI remain selected.
- OpenWrt target checksums and the collected-artifact checksums both passed.

Samba/ksmbd, HFS+, and APFS support are intentionally not included. IPsec
kernel support is included, but a user-space daemon such as strongSwan is not.

## Hardware validation status

The exact published `beryl7.3` sysupgrade image was flashed to a
GL-MT3600BE on 2026-10-16 with settings preserved. Its SHA-256 matched the
Release, the on-device `sysupgrade -T` image check passed, and the router
rebooted successfully into
`OpenWrt 25.12-SNAPSHOT r0+32742-7e35c47c00-beryl7.3`.

Post-upgrade hardware checks passed for:

- wired LAN and WAN, both configured wireless radios, key-only SSH, LuCI, and
  the Japanese login UI;
- `apk update` with all official indexes available and no active
  `mtk_openwrt_feed` runtime repository;
- Tailscale service/state preservation, TUN, nftables mode, direct peer
  connectivity, UDP, IPv4, and IPv6;
- the USB 3 xHCI root hub at `20000M/x2`, with a SanDisk USB 3 storage device
  attached at `5000M` using the `uas` driver;
- ext4 detection and automatic mounting at `/mnt/sda1` with
  `anon_mount=1` and `auto_mount=1`;
- a read-only 256 MiB block-device read, with no new USB reset or I/O error;
- automatic fan control at PWM 176 / approximately 4240 RPM while the CPU and
  2.5GbE thermal zones were approximately 60-61 degrees Celsius; and
- the requested USB tethering, IPsec/XFRM/VTI, nft flow-offload, and
  Safexcel-related package/module inventory.

The retained pre-upgrade LuCI configuration selected an OpenWrt2020 theme that
is not included in this image. LuCI correctly fell back to Bootstrap, after
which the stale theme selection was changed to Bootstrap and the Japanese UI
was rechecked.

Two xHCI diagnostics saying `Transfer event 26 for unknown stream ring` were
logged during initial UAS enumeration. The device remained mounted, the
read-only transfer passed, and no reset or I/O error followed. Long-duration
storage monitoring is still recommended.

Actual phone/modem tethering, a configured IPsec tunnel, sustained hardware
flow-offload throughput, full Wi-Fi 7 mode/performance coverage, sustained
2.5GbE traffic, power use, and long-duration stability remain to be validated.
The fw4 flowtable is available but was intentionally not enabled during this
test. IPsec kernel support is present; its user-space daemon is still not
included.

## Safety status

This is a custom pre-release, not an official OpenWrt or GL.iNet firmware. It
does not include the GL.iNet UI, proprietary services, or the closed `mt_wifi7`
driver; it uses the MediaTek public-feed-enhanced `mac80211`/`mt76` stack. Use
it only on a GL.iNet GL-MT3600BE, preserve backup and recovery access, do not
run blanket `apk upgrade`, and do not force-install official snapshot
`kmod-*` packages over this custom kernel ABI.
