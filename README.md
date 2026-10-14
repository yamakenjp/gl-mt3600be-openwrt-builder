# GL-MT3600BE: OpenWrt 25.12 + MediaTek public feed

GL.iNET Beryl 7（GL-MT3600BE）向けの、ソースrevisionを固定したカスタムOpenWrtビルド一式です。OpenWrt 25.12を基点に、MediaTek公開feedのWi-Fi 7 / Filogic変更と、OpenWrt公式のBeryl 7デバイス定義を組み合わせます。

これはGL.iNET公式ファームではありません。GL.iNET独自UI・独自サービス・クローズドな`mt_wifi7` vendor driverは入りません。Wi-FiはMediaTek公開feedが拡張した`mac80211` / `mt76`系です。

## 配布ファームウェア

完成イメージはGit履歴には含めず、[GitHub Releases](https://github.com/yamakenjp/gl-mt3600be-openwrt-builder/releases)で配布します。正確なサイズ、SHA-256、内部検査結果は[`BUILD-RESULT.md`](BUILD-RESULT.md)を参照してください。

- `*squashfs-sysupgrade.bin`: GL-MT3600BEへ通常導入するイメージ
- `*initramfs-kernel.bin`: RAM起動・復旧・検証向けの上級者用イメージ
- `SHA256SUMS`: 配布対象2イメージのみのチェックサム

このプロジェクトは`factory`イメージを生成しません。bootloader / BL2イメージも配布しません。

ダウンロード後は必ず確認してください。

```sh
shasum -a 256 -c SHA256SUMS
```

## 実機確認状況

配布中のsysupgradeイメージはGL-MT3600BE実機で次を確認済みです。

- sysupgrade後の起動
- Ethernet LAN経由のSSHログイン
- LuCIへのログイン
- 後述のローカルfeed行を除去した後の`apk update`
- LuCI日本語翻訳パッケージの追加

Wi-Fi 7の全モード、2.5GbEの長時間安定性、hardware offload、USB、性能・熱・消費電力は網羅的には検証していません。

## 固定しているソース

| 要素 | 固定値 |
|---|---|
| OpenWrt `openwrt-25.12` | `34ae6ba2d861e710e3c130c95cdb7eb4a1286121` |
| Beryl 7公式デバイスcommit | `c8aa9beb4379f7e742350d44a0c150e98c99e2cd` |
| MediaTek公開feed（MP4.3） | `9b5754e3a361635595ea31a14176b14169e69d18` |
| MediaTek autobuild profile | `filogic-mac80211-mt7987_rfb-mt7990` |
| packages feed | `ab3b874a7df14e99179d5f17b77284ad66fa18b7` |
| LuCI feed | `11264f9297b0ad272f0bd2f288b088f71bf63918` |
| routing feed | `5b23ea12d417e5dba99788c5b34abdae81cccf33` |

デバイス設定は[`configs/beryl7-mtk.config`](configs/beryl7-mtk.config)です。Beryl 7のみを対象にし、LuCIと日本語翻訳、relay、MediaTek flow-offload補助、USBストレージ関連を含め、HQA / デバッグ用途のパッケージは外しています。

Beryl 7の公式デバイス定義が選ぶ`mt7987-2p5g-phy-firmware`と、MediaTek公開feedの2.5GbE driver `kmod-mt798x-2p5g-phy`を組み合わせます。MediaTek側driverの依存先を内部版firmwareから公式MT7987 firmwareへ変更する処理は、[`patches/0001-mtk-2p5g-use-openwrt-mt7987-firmware.patch`](patches/0001-mtk-2p5g-use-openwrt-mt7987-firmware.patch)として明示しています。

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

## 配布イメージ導入後の注意

### MediaTekローカルfeed行

初回Release（`v25.12-snapshot-20261006`）のイメージには、ビルド時だけ存在する`mtk_openwrt_feed`が誤って配布リポジトリとして残っています。このfeedはOpenWrt公式サーバーにはないため、導入後に一度だけ削除してください。組み込み済みMediaTek driverやパッケージは削除されません。現在の`main`はこのfeedをコメントアウトして生成します。

```sh
cp -p /etc/apk/repositories.d/distfeeds.list /root/distfeeds.list.bak
sed -i '/mtk_openwrt_feed/d' /etc/apk/repositories.d/distfeeds.list
apk update
```

### LuCIの日本語化

現在の`main`から作るイメージには日本語翻訳を組み込みます。初回Releaseへ後から追加する場合は次を実行します。

```sh
apk add luci-i18n-base-ja luci-i18n-firewall-ja luci-i18n-package-manager-ja
uci set luci.main.lang='ja'
uci commit luci
/etc/init.d/uhttpd restart
```

### パッケージ更新

- `apk upgrade`による一括更新は行わないでください。
- 公式snapshotの`kmod-*`を強制導入しないでください。このカスタムkernelとABIが一致しない場合があります。
- 必要なユーザー空間パッケージだけを、依存関係を確認して`apk add <package>`で追加してください。

## 書き込み前の安全確認

- 対象機種がGL.iNET GL-MT3600BEであることを確認してください。
- GL.iNET純正ファーム、設定、重要なMTD / calibration情報の復旧手段を別途確保してください。
- vendor firmwareからは設定を引き継がず、クリーンなsysupgradeを推奨します。
- `sysupgrade.bin`だけを通常更新に使用し、initramfsや他機種のイメージをsysupgradeしないでください。
- シリアルまたはU-Boot recoveryを含む復旧経路を把握してから導入してください。

## ライセンスと出典

このリポジトリのビルド補助、設定、パッチは`GPL-2.0-only`です。取得・ビルドされるOpenWrt、Linux、MediaTek公開feed、各パッケージと配布バイナリには、それぞれの上流ライセンスが適用されます。詳細は[`NOTICE.md`](NOTICE.md)を参照してください。
