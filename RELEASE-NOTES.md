# OpenWrt 25.12-SNAPSHOT for GL.iNET GL-MT3600BE

Tag: `v25.12-snapshot-20261016.3`

OpenWrt 25.12-SNAPSHOTとMediaTek公開feed（MP4.3）を組み合わせた、GL.iNET Beryl 7（GL-MT3600BE）専用の`beryl7.3`カスタムビルドです。USB 3 controller設定を修正したpre-releaseです。

## 通常更新に使うファイル

`openwrt-mediatek-filogic-glinet_gl-mt3600be-squashfs-sysupgrade.bin`

`initramfs-kernel.bin`はRAM起動・復旧・検証向けです。通常のsysupgradeには使わないでください。このReleaseにfactory imageやbootloader / BL2 imageはありません。正確なSHA-256は同じReleaseの`SHA256SUMS`で確認してください。

通常更新用sysupgradeのサイズ、SHA-256、GitHub Actions run IDは、検査合格後にこのRelease本文へ自動追記されます。正確な値は同じReleaseの`SHA256SUMS`でも確認してください。

## `beryl7.3`の追加・修正内容

- Beryl 7のUSB controllerへUSB 2 / USB 3 PHYを正しく接続し、無効化されていたSuperSpeed portを有効化
- 設定保持sysupgradeでも既存のfstab mount entryを残したまま、匿名USB automountを有効化する移行処理
- Tailscale 1.102.3と一致する`kmod-tun`
- Tailscaleのビルドに使うhost Go toolchainを、公式OpenWrt 25.12由来の1.26.9へ更新
- LuCI日本語翻訳を初期イメージへ同梱
- WireGuard tools/LuCI、veth、SQM/CAKE tools/LuCI、nftables socket/tproxy module
- Android/iPhone USBテザリング（iPhone pairing toolsを含む）、MBIM/QMI/NCM modem、主要USB Ethernet adapter
- USB/UAS block-mount、exFAT、kernel NTFS3 read/write
- IPsec/XFRM/VTIのkernel module（strongSwanなどuser space daemonは未同梱）
- CPUと2.5GbEの高い温度に追従する4段階PWMファン制御
- MediaTek flow offload/WED、EIP/Safexcel暗号化支援を維持
- 存在しない`mtk_openwrt_feed`のruntime URLを無効化

ファンカーブは50/60/70/80℃でPWM 128/176/224/255、各段のヒステリシスは5℃です。最初の段は実機で回転を確認したPWM 128を使用しますが、この新しい自動カーブを含むイメージは導入後に改めて確認してください。

community版Tailscale LuCI applicationは、固定LuCI revisionに[既知のcommand injection問題](https://github.com/advisories/GHSA-xwc5-mx58-rh35)があるため含めていません。

## 更新手順

現在のOpenWrt設定を引き継ぐ場合も、先にbackupを取得してください。SSHから更新する例です。

```sh
scp openwrt-mediatek-filogic-glinet_gl-mt3600be-squashfs-sysupgrade.bin \
  root@192.168.81.1:/tmp/beryl7.3-sysupgrade.bin
ssh root@192.168.81.1
sysupgrade -T /tmp/beryl7.3-sysupgrade.bin
sysupgrade /tmp/beryl7.3-sysupgrade.bin
```

vendor firmwareから移行する場合は設定を保持せず、復旧手段を用意した上で行ってください。初回Releaseからの更新では通常のconfig保持を想定していますが、旧Release用の外部`kmod-*`を残したり再利用したりしないでください。

## Tailscale開始

```sh
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
tailscale up --accept-dns=false
```

表示されたURLで認証します。Tailscaleのclient自己更新は無効です。

## 重要な注意

- sysupgradeイメージと`SHA256SUMS`を同じ場所へ保存し、書き込み前に`grep 'squashfs-sysupgrade\.bin$' SHA256SUMS | shasum -a 256 -c -`で照合してください。
- `apk upgrade`の一括実行は避けてください。
- 公式snapshotの`kmod-*`を強制導入しないでください。
- GL-MT3600BE以外へ書き込まないでください。
- 純正ファーム、MTD/calibration情報、U-Boot recoveryまたはserial consoleなどの復旧経路を確保してください。
- USB 3/UASでの列挙と自動マウント、新しい自動ファン制御、IPsec、長時間負荷は導入後の実機確認が必要です。

これはOpenWrt公式ReleaseでもGL.iNet公式ファームでもありません。GL.iNet独自UI、独自service、closed `mt_wifi7` driverは含まず、MediaTek公開feedが拡張した`mac80211`/`mt76` stackを使用します。
