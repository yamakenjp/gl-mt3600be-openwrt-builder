# OpenWrt 25.12-SNAPSHOT for GL.iNET GL-MT3600BE

Tag: `v25.12-snapshot-20261006`

OpenWrt 25.12-SNAPSHOTとMediaTek公開feed（MP4.3）を組み合わせた、GL.iNET Beryl 7（GL-MT3600BE）専用のカスタムビルドです。

## 通常更新に使うファイル

`openwrt-mediatek-filogic-glinet_gl-mt3600be-squashfs-sysupgrade.bin`

- SHA-256: `250186132ffa714d0259cae72fcd7852282f6c2796580bc82d6ce0900dddce86`
- サイズ: `15,626,525` bytes
- 対象: `glinet,gl-mt3600be`のみ

`initramfs-kernel.bin`はRAM起動・復旧・検証向けです。通常のsysupgradeには使わないでください。このReleaseにfactory imageやbootloader / BL2 imageはありません。

## 確認済み

- 実機でのsysupgradeと起動
- Ethernet LAN、SSH、LuCI
- APKリポジトリ修正後の`apk update`
- LuCI日本語パッケージの導入

Wi-Fi 7、2.5GbE、offload、USB、性能と熱は網羅的には未検証です。

## 導入直後に必要な修正

このイメージにはビルド専用の`mtk_openwrt_feed`行が残っています。最初のSSHログイン後、一度だけ実行してください。

```sh
cp -p /etc/apk/repositories.d/distfeeds.list /root/distfeeds.list.bak
sed -i '/mtk_openwrt_feed/d' /etc/apk/repositories.d/distfeeds.list
apk update
```

`apk upgrade`の一括実行や、公式snapshotの`kmod-*`の強制導入は避けてください。

## LuCI日本語化（任意）

```sh
apk add luci-i18n-base-ja luci-i18n-firewall-ja luci-i18n-package-manager-ja
uci set luci.main.lang='ja'
uci commit luci
/etc/init.d/uhttpd restart
```

書き込み前に`SHA256SUMS`を照合し、純正ファーム・MTD/calibration情報・復旧経路を確保してください。
