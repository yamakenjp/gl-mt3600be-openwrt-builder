# GL-MT3600BE: OpenWrt 25.12 + MediaTek public feed

GL.iNET Beryl 7（GL-MT3600BE）向けの、ソースrevisionを固定したカスタムOpenWrtビルド一式です。OpenWrt 25.12を基点に、MediaTek公開feedのWi-Fi 7 / Filogic変更と、OpenWrt公式のBeryl 7デバイス定義を組み合わせます。現在のビルド番号は`beryl7.3`、Release tagは`v25.12-snapshot-20261016.3`です。

これはGL.iNET公式ファームではありません。GL.iNET独自UI・独自サービス・クローズドな`mt_wifi7` vendor driverは入りません。Wi-FiはMediaTek公開feedが拡張した`mac80211` / `mt76`系です。

## 配布ファームウェア

完成イメージはGit履歴には含めず、[GitHub Releases](https://github.com/yamakenjp/gl-mt3600be-openwrt-builder/releases)で配布します。正確なサイズ、SHA-256、内部検査結果は[`BUILD-RESULT.md`](BUILD-RESULT.md)を参照してください。

- `*squashfs-sysupgrade.bin`: GL-MT3600BEへ通常導入するイメージ
- `*initramfs-kernel.bin`: RAM起動・復旧・検証向けの上級者用イメージ
- `SHA256SUMS`: ファームウェアと監査用buildinfo一式のチェックサム

このプロジェクトは`factory`イメージを生成しません。bootloader / BL2イメージも配布しません。

通常更新用のsysupgradeイメージと`SHA256SUMS`を同じディレクトリへダウンロードし、必ず確認してください。

```sh
grep 'squashfs-sysupgrade\.bin$' SHA256SUMS | shasum -a 256 -c -
```

## 実機確認状況

`v25.12-snapshot-20261016.3`で公開した`beryl7.3`のsysupgradeイメージを
GL-MT3600BE実機へ設定保持で導入し、正常起動を確認済みです。

- Ethernet LAN / WAN、両wireless radio、SSH、LuCI日本語画面
- `apk update`（無効なMediaTek runtime feedへのアクセスなし）
- Tailscale、TUN、nftables、UDP、peerとの直接接続
- USB 3 root hub、5 Gbps接続、UAS、ext4の自動マウント
- USBストレージからのread-only 256 MiB読み出し（reset / I/O errorなし）
- CPU / 2.5GbE温度連動の自動ファン制御
- USBテザリング、IPsec/XFRM/VTI、flow offload、Safexcelのpackage/module搭載

保持されていた旧`openwrt2020`テーマ設定は、このイメージに同テーマが
入っていないためBootstrapへ変更しました。実測値、USBログ上の注意点、
未検証項目は[`BUILD-RESULT.md`](BUILD-RESULT.md)に記録しています。

実機を用いた電話・モデムのUSBテザリング、IPsec tunnel、hardware
flow-offloadの性能、Wi-Fi 7全モード、2.5GbE長時間負荷、消費電力、
長期安定性は引き続き未検証です。

## 固定しているソース

| 要素 | 固定値 |
|---|---|
| OpenWrt `openwrt-25.12` | `34ae6ba2d861e710e3c130c95cdb7eb4a1286121` |
| Beryl 7公式デバイスcommit | `c8aa9beb4379f7e742350d44a0c150e98c99e2cd` |
| MediaTek公開feed（MP4.3） | `9b5754e3a361635595ea31a14176b14169e69d18` |
| MediaTek autobuild profile | `filogic-mac80211-mt7987_rfb-mt7990` |
| packages feed | `ab3b874a7df14e99179d5f17b77284ad66fa18b7` |
| Tailscale recipe final state | `5d6ecf4803ed041c9f76271e1d1e27e976a68c72`（1.102.3） |
| Host Go recipe final state | `54fab7fa4224193a121f49a9f39dafd9323a0b2d`（1.26.9） |
| LuCI feed | `11264f9297b0ad272f0bd2f288b088f71bf63918` |
| routing feed | `5b23ea12d417e5dba99788c5b34abdae81cccf33` |

デバイス設定は[`configs/beryl7-mtk.config`](configs/beryl7-mtk.config)です。Beryl 7のみを対象にし、次をファームウェアへ組み込みます。

- LuCIと日本語翻訳、relay
- Tailscale 1.102.3と同じkernel ABIの`kmod-tun`
- WireGuard tools/LuCI、veth、SQM/CAKE tools/LuCI、nftables socket/tproxy
- Android/iPhone USBテザリング（iPhone pairing toolsを含む）、MBIM/QMI/NCMモデム、主要USB Ethernet adapter
- USB/UASストレージ、block-mount、ext4/VFAT/exFAT、kernel NTFS3 read/write
- Beryl 7のUSB controllerへUSB 2 / USB 3 PHYを接続するDevice Tree修正
- sysupgradeで保持されたfstabの既存mount entryを残したまま、匿名USB automountを有効化するUCI migration
- IPsec/XFRM/VTIのkernel側（strongSwanなどのuser space daemonは未同梱）
- MediaTek flow offload/WED、EIP/Safexcel暗号化支援
- CPUと2.5GbE温度に連動するPWMファン制御

HQA / デバッグ用途のパッケージは外しています。MT7988専用のinline IPsec offloadはMT7987のBeryl 7には適用していません。

Beryl 7の公式デバイス定義が選ぶ`mt7987-2p5g-phy-firmware`と、MediaTek公開feedの2.5GbE driver `kmod-mt798x-2p5g-phy`を組み合わせます。MediaTek側driverの依存先を内部版firmwareから公式MT7987 firmwareへ変更する処理は、[`patches/0001-mtk-2p5g-use-openwrt-mt7987-firmware.patch`](patches/0001-mtk-2p5g-use-openwrt-mt7987-firmware.patch)として明示しています。

Tailscale更新は[`patches/0002-tailscale-1.102.3.patch`](patches/0002-tailscale-1.102.3.patch)、自動ファンカーブは[`patches/0003-beryl7-thermal-fan-curve.patch`](patches/0003-beryl7-thermal-fan-curve.patch)、Tailscaleの最低要件を満たすGo 1.26.9更新は[`patches/0004-golang-1.26.9.patch`](patches/0004-golang-1.26.9.patch)、USB 3 PHY有効化は[`patches/0005-beryl7-enable-usb3.patch`](patches/0005-beryl7-enable-usb3.patch)として分離しています。ファンはCPUまたは2.5GbEの高い方を基準に、50/60/70/80℃でPWM 128/176/224/255へ上げ、各段に5℃のヒステリシスを持たせます。最初の段には実機で回転を確認したPWM 128を使用します。

ここでいう「ソース固定」は取得revisionを固定するという意味です。ホストtoolchain、署名鍵、commit timestampなども含めたbit-for-bit reproducible buildは保証しません。

## 必要条件

- Linuxの大文字・小文字を区別するファイルシステム
- 空き容量15GB以上（余裕をみるなら25GB）
- RAM 8GB推奨。少ない環境ではswapを用意し、`JOBS=1`または`JOBS=2`を使用
- Git、GNU make、C/C++ toolchain、Python 3、Perl、rsync、swig、unzipなどOpenWrtの標準ビルド依存関係

Ubuntu / Debian系の目安です。

```sh
sudo apt update
sudo apt install build-essential clang flex bison gawk gettext git \
  libelf-dev libncurses-dev libssl-dev python3 python3-setuptools \
  rsync swig unzip wget zlib1g-dev file
```

## ビルド

```sh
git clone https://github.com/yamakenjp/gl-mt3600be-openwrt-builder.git
cd gl-mt3600be-openwrt-builder
bash ./build-beryl7-mtk.sh
```

スクリプトは標準では`work/`へソースを取得します。ルーターへの書き込み処理は一切ありません。低容量環境向けに`AUTOREMOVE=1`が既定です。

メモリに余裕がある場合のみ並列数を増やせます。

```sh
JOBS=4 DOWNLOAD_JOBS=8 bash ./build-beryl7-mtk.sh
```

保存先を変える場合は`WORK_DIR`と`OUTPUT_DIR`を指定します。既存ツリーのrevisionが固定値と異なる場合、スクリプトは上書きやresetをせず停止します。

```sh
WORK_DIR=/path/to/build-work OUTPUT_DIR=/path/to/result \
  bash ./build-beryl7-mtk.sh
```

ビルド後のファームウェア、`SHA256SUMS`、`profiles.json`、buildinfo、最終`.config`は`output-repro/`へ集められます。失敗内容を詳しく確認する場合は、表示された作業ディレクトリで`make -j1 V=s`を実行してください。

`.github/workflows/build-release.yml`は、固定されたtag名についてクリーンなGitHub runner上で同じ手順を実行し、構成・チェックサム・Tailscale versionを検証してpre-releaseを作成します。

Actionsの再実行時間を抑えるため、checksumで検証されるdownload archive、Go module/build cache、最大2 GiBのcompiler cacheだけをビルド入力hashごとに再利用します。MediaTekの事前処理で取得するarchiveも同じdownload cacheを使い、ビルド途中で失敗した場合は再開用のpartial cacheを別keyで保存します。kernel build tree、`staging_dir`、rootfsはcacheから再利用せず、毎回クリーンに組み立てます。

ビルドとRelease検査は別jobです。正常に生成されchecksum検査を通った完成出力は、短期artifactに加えてビルド入力hashが完全一致する専用cacheにも保存します。そのため検査処理だけの再実行や、検査workflowだけを修正した場合は、同じファームを復元して長時間の再コンパイルを避けられます。

ローカルでも同じcache機構を使う場合は、OpenWrt作業treeの外にある空白を含まない絶対pathを指定します。`COMPILER_CACHE_DIR`を使う場合は`ccache`が必要です。

```sh
DOWNLOAD_CACHE_DIR=/path/to/cache/downloads \
COMPILER_CACHE_DIR=/path/to/cache/ccache \
GOLANG_BUILD_CACHE_DIR=/path/to/cache/go-build \
bash ./build-beryl7-mtk.sh
```

## 配布イメージ導入後の注意

### MediaTekローカルfeed行

初回Release（`v25.12-snapshot-20261006`）のイメージには、ビルド時だけ存在する`mtk_openwrt_feed`が誤って配布リポジトリとして残っています。このfeedはOpenWrt公式サーバーにはないため、導入後に一度だけ削除してください。組み込み済みMediaTek driverやパッケージは削除されません。現在の`main`はこのfeedをコメントアウトして生成します。

```sh
cp -p /etc/apk/repositories.d/distfeeds.list /root/distfeeds.list.bak
sed -i '/mtk_openwrt_feed/d' /etc/apk/repositories.d/distfeeds.list
apk update
```

### LuCIの日本語化

`beryl7.3`には日本語翻訳を組み込み、日本語を初回boot時の既定値にします。初回Releaseへ後から追加する場合は次を実行します。

```sh
apk add luci-i18n-base-ja luci-i18n-firewall-ja luci-i18n-package-manager-ja
uci set luci.main.lang='ja'
uci commit luci
/etc/init.d/uhttpd restart
```

### Tailscale

`beryl7.3`はTailscale 1.102.3と一致する`kmod-tun`を同梱します。community LuCI applicationは[既知のcommand injection問題](https://github.com/advisories/GHSA-xwc5-mx58-rh35)がある固定revisionのため採用せず、公式CLIを使用します。

```sh
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
tailscale up --accept-dns=false
```

表示されたURLで認証してください。Tailscaleのclient自己更新は無効で、更新はこのファームウェア側で行います。subnet routerやexit nodeとして使う場合は、用途に応じたforwardingとfirewall設定も別途必要です。

### 自動ファン制御

温度確認には次を使用できます。通常はthermal subsystemに任せ、`pwm1`へ常時値を書き込むスクリプトを併用しないでください。

```sh
for z in /sys/class/thermal/thermal_zone*; do
  echo "$z $(cat "$z/type") $(cat "$z/temp")"
done
cat /sys/class/hwmon/hwmon*/fan1_input 2>/dev/null
```

### パッケージ更新

- `apk upgrade`による一括更新は行わないでください。
- 公式snapshotの`kmod-*`を強制導入しないでください。このカスタムkernelとABIが一致しない場合があります。
- 必要なユーザー空間パッケージだけを、依存関係を確認して`apk add <package>`で追加してください。
- 旧Release用に配布したkernel moduleを`beryl7.3`へ流用しないでください。kernel ABIが変わる場合があるため、新しいsysupgradeイメージ内のmodule一式を使用します。

## 書き込み前の安全確認

- 対象機種がGL.iNET GL-MT3600BEであることを確認してください。
- GL.iNET純正ファーム、設定、重要なMTD / calibration情報の復旧手段を別途確保してください。
- vendor firmwareからは設定を引き継がず、クリーンなsysupgradeを推奨します。
- `sysupgrade.bin`だけを通常更新に使用し、initramfsや他機種のイメージをsysupgradeしないでください。
- シリアルまたはU-Boot recoveryを含む復旧経路を把握してから導入してください。

## ライセンスと出典

このリポジトリのビルド補助、設定、パッチは`GPL-2.0-only`です。取得・ビルドされるOpenWrt、Linux、MediaTek公開feed、各パッケージと配布バイナリには、それぞれの上流ライセンスが適用されます。詳細は[`NOTICE.md`](NOTICE.md)を参照してください。
