#!/usr/bin/env bash

# GL.iNET Beryl 7 (GL-MT3600BE)
# OpenWrt 25.12 + MediaTek public feed source-pinned build helper.
#
# This script builds firmware only. It never writes to a router or invokes a
# flashing tool. By default it uses ./work so that the already prepared source
# trees in this directory are not modified.

set -Eeuo pipefail

readonly OPENWRT_URL="https://github.com/openwrt/openwrt.git"
readonly OPENWRT_BRANCH="openwrt-25.12"
readonly OPENWRT_SHA="34ae6ba2d861e710e3c130c95cdb7eb4a1286121"
readonly BERYL7_COMMIT="c8aa9beb4379f7e742350d44a0c150e98c99e2cd"

readonly MTK_FEED_URL="https://github.com/mediatek/mtk-openwrt-feeds.git"
readonly MTK_FEED_SHA="9b5754e3a361635595ea31a14176b14169e69d18"
readonly MTK_PROFILE="filogic-mac80211-mt7987_rfb-mt7990"

readonly PACKAGES_SHA="ab3b874a7df14e99179d5f17b77284ad66fa18b7"
readonly LUCI_SHA="11264f9297b0ad272f0bd2f288b088f71bf63918"
readonly ROUTING_SHA="5b23ea12d417e5dba99788c5b34abdae81cccf33"
readonly TAILSCALE_PACKAGE_COMMIT="5d6ecf4803ed041c9f76271e1d1e27e976a68c72"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-${SCRIPT_DIR}/work}"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/output-repro}"
CONFIG_SEED="${SCRIPT_DIR}/configs/beryl7-mtk.config"
FILES_OVERLAY="${SCRIPT_DIR}/files"
MTK_2P5G_PATCH="${SCRIPT_DIR}/patches/0001-mtk-2p5g-use-openwrt-mt7987-firmware.patch"
TAILSCALE_PATCH="${SCRIPT_DIR}/patches/0002-tailscale-1.102.3.patch"
FAN_CURVE_PATCH="${SCRIPT_DIR}/patches/0003-beryl7-thermal-fan-curve.patch"
OPENWRT_DIR="${WORK_DIR}/openwrt"
MTK_FEED_DIR="${WORK_DIR}/mtk-openwrt-feeds"
JOBS="${JOBS:-2}"
DOWNLOAD_JOBS="${DOWNLOAD_JOBS:-4}"
AUTOREMOVE="${AUTOREMOVE:-1}"

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

note() {
    printf '\n==> %s\n' "$*"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

for command_name in bash git make gcc g++ awk patch perl python3 rsync swig unzip wget file sha256sum; do
    require_command "${command_name}"
done

[[ "${JOBS}" =~ ^[1-9][0-9]*$ ]] || die "JOBS must be a positive integer"
[[ "${DOWNLOAD_JOBS}" =~ ^[1-9][0-9]*$ ]] || die "DOWNLOAD_JOBS must be a positive integer"
[[ "${AUTOREMOVE}" =~ ^[01]$ ]] || die "AUTOREMOVE must be 0 or 1"
[[ -f "${CONFIG_SEED}" ]] || die "Configuration seed not found: ${CONFIG_SEED}"
[[ -d "${FILES_OVERLAY}" ]] || die "Root filesystem overlay not found: ${FILES_OVERLAY}"
[[ -f "${MTK_2P5G_PATCH}" ]] || die "2.5GbE integration patch not found: ${MTK_2P5G_PATCH}"
[[ -f "${TAILSCALE_PATCH}" ]] || die "Tailscale backport patch not found: ${TAILSCALE_PATCH}"
[[ -f "${FAN_CURVE_PATCH}" ]] || die "Beryl 7 fan curve patch not found: ${FAN_CURVE_PATCH}"
[[ "${WORK_DIR}" != "/" ]] || die "WORK_DIR must not be /"
[[ "${WORK_DIR}" != "${HOME:-/nonexistent}" ]] || die "WORK_DIR must not be the home directory"

mkdir -p "${WORK_DIR}"

openwrt_was_cloned=0
if [[ ! -e "${OPENWRT_DIR}" ]]; then
    note "Cloning OpenWrt"
    git clone --filter=blob:none --branch "${OPENWRT_BRANCH}" \
        "${OPENWRT_URL}" "${OPENWRT_DIR}"
    openwrt_was_cloned=1
fi
[[ -d "${OPENWRT_DIR}/.git" ]] || die "Not an OpenWrt Git tree: ${OPENWRT_DIR}"

if ! git -C "${OPENWRT_DIR}" cat-file -e "${OPENWRT_SHA}^{commit}" 2>/dev/null; then
    note "Fetching the pinned OpenWrt commit"
    git -C "${OPENWRT_DIR}" fetch --filter=blob:none origin "${OPENWRT_SHA}"
fi
if ! git -C "${OPENWRT_DIR}" cat-file -e "${BERYL7_COMMIT}^{commit}" 2>/dev/null; then
    note "Fetching the upstream Beryl 7 device commit"
    git -C "${OPENWRT_DIR}" fetch --filter=blob:none origin "${BERYL7_COMMIT}"
fi

if (( openwrt_was_cloned )); then
    git -C "${OPENWRT_DIR}" switch --create beryl7-mtk "${OPENWRT_SHA}"
fi

openwrt_head="$(git -C "${OPENWRT_DIR}" rev-parse HEAD)"
if [[ "${openwrt_head}" == "${OPENWRT_SHA}" ]]; then
    [[ -z "$(git -C "${OPENWRT_DIR}" status --porcelain)" ]] || \
        die "OpenWrt tree has changes before the Beryl 7 commit is applied"

    note "Applying the official Beryl 7 device profile"
    git -C "${OPENWRT_DIR}" config user.name "Beryl 7 reproducible build"
    git -C "${OPENWRT_DIR}" config user.email "beryl7-build@localhost"
    git -C "${OPENWRT_DIR}" cherry-pick "${BERYL7_COMMIT}"
else
    openwrt_parent="$(git -C "${OPENWRT_DIR}" show -s --format=%P HEAD)"
    openwrt_subject="$(git -C "${OPENWRT_DIR}" show -s --format=%s HEAD)"
    [[ "${openwrt_parent}" == "${OPENWRT_SHA}" ]] || \
        die "Existing OpenWrt tree is not based directly on ${OPENWRT_SHA}"
    [[ "${openwrt_subject}" == "mediatek: add GL.iNET GL-MT3600BE support" ]] || \
        die "Existing OpenWrt tree does not contain the expected Beryl 7 cherry-pick"
fi

mtk_was_cloned=0
if [[ ! -e "${MTK_FEED_DIR}" ]]; then
    note "Cloning the MediaTek public feed"
    git clone --filter=blob:none "${MTK_FEED_URL}" "${MTK_FEED_DIR}"
    mtk_was_cloned=1
fi
[[ -d "${MTK_FEED_DIR}/.git" ]] || die "Not a MediaTek feed Git tree: ${MTK_FEED_DIR}"

if ! git -C "${MTK_FEED_DIR}" cat-file -e "${MTK_FEED_SHA}^{commit}" 2>/dev/null; then
    note "Fetching the pinned MediaTek feed commit"
    git -C "${MTK_FEED_DIR}" fetch --filter=blob:none origin "${MTK_FEED_SHA}"
fi
if (( mtk_was_cloned )); then
    git -C "${MTK_FEED_DIR}" switch --detach "${MTK_FEED_SHA}"
fi
[[ "$(git -C "${MTK_FEED_DIR}" rev-parse HEAD)" == "${MTK_FEED_SHA}" ]] || \
    die "Existing MediaTek feed tree is not at ${MTK_FEED_SHA}"

note "Pinning OpenWrt feed revisions"
mkdir -p "${MTK_FEED_DIR}/autobuild/unified"
cat >"${MTK_FEED_DIR}/autobuild/unified/feed_revision" <<EOF
packages ${PACKAGES_SHA}
luci ${LUCI_SHA}
routing ${ROUTING_SHA}
EOF

note "Preparing OpenWrt with the MediaTek ${MTK_PROFILE} profile"
(
    cd "${OPENWRT_DIR}"

    # Use the official GitHub mirrors for the standard OpenWrt feeds. The
    # pinned object IDs remain the same as on git.openwrt.org.
    env \
        GIT_CONFIG_COUNT=4 \
        GIT_CONFIG_KEY_0='url.https://github.com/openwrt/packages.git.insteadOf' \
        GIT_CONFIG_VALUE_0='https://git.openwrt.org/feed/packages.git' \
        GIT_CONFIG_KEY_1='url.https://github.com/openwrt/luci.git.insteadOf' \
        GIT_CONFIG_VALUE_1='https://git.openwrt.org/project/luci.git' \
        GIT_CONFIG_KEY_2='url.https://github.com/openwrt/routing.git.insteadOf' \
        GIT_CONFIG_VALUE_2='https://git.openwrt.org/feed/routing.git' \
        GIT_CONFIG_KEY_3='url.https://github.com/openwrt/telephony.git.insteadOf' \
        GIT_CONFIG_VALUE_3='https://git.openwrt.org/feed/telephony.git' \
        bash "${MTK_FEED_DIR}/autobuild/unified/autobuild.sh" \
        "${MTK_PROFILE}" prepare
)

note "Combining the MediaTek 2.5GbE driver with the official MT7987 firmware"
mtk_2p5g_makefile="feed/app/mt798x-2p5g-phy-firmware-internal/Makefile"
if patch --dry-run --batch --forward -p1 -d "${MTK_FEED_DIR}" \
        <"${MTK_2P5G_PATCH}" >/dev/null 2>&1; then
    patch --batch --forward -p1 -d "${MTK_FEED_DIR}" <"${MTK_2P5G_PATCH}"
elif patch --dry-run --batch --reverse -p1 -d "${MTK_FEED_DIR}" \
        <"${MTK_2P5G_PATCH}" >/dev/null 2>&1; then
    note "The 2.5GbE integration patch is already applied"
else
    die "The 2.5GbE integration patch is neither applicable nor already applied"
fi

grep -Fqx '  DEPENDS:=@TARGET_mediatek +mt7987-2p5g-phy-firmware' \
    "${MTK_FEED_DIR}/${mtk_2p5g_makefile}" || \
    die "The MediaTek 2.5GbE driver does not depend on the expected MT7987 firmware"

note "Backporting Tailscale 1.102.3 from OpenWrt packages ${TAILSCALE_PACKAGE_COMMIT}"
packages_feed_dir="${OPENWRT_DIR}/feeds/packages"
[[ -d "${packages_feed_dir}/net/tailscale" ]] || \
    die "Prepared packages feed does not contain net/tailscale"
if patch --dry-run --batch --forward -p1 -d "${packages_feed_dir}" \
        <"${TAILSCALE_PATCH}" >/dev/null 2>&1; then
    patch --batch --forward -p1 -d "${packages_feed_dir}" <"${TAILSCALE_PATCH}"
elif patch --dry-run --batch --reverse -p1 -d "${packages_feed_dir}" \
        <"${TAILSCALE_PATCH}" >/dev/null 2>&1; then
    note "The Tailscale backport patch is already applied"
else
    die "The Tailscale 1.102.3 patch is neither applicable nor already applied"
fi

grep -Fqx 'PKG_VERSION:=1.102.3' \
    "${packages_feed_dir}/net/tailscale/Makefile" || \
    die "Unexpected Tailscale version after backport"
grep -Fq 'ts_omit_clientupdate' \
    "${packages_feed_dir}/net/tailscale/Makefile" || \
    die "Tailscale client self-update must remain disabled"

note "Adding the Beryl 7 CPU and 2.5GbE automatic fan curve"
if patch --dry-run --batch --forward -p1 -d "${OPENWRT_DIR}" \
        <"${FAN_CURVE_PATCH}" >/dev/null 2>&1; then
    patch --batch --forward -p1 -d "${OPENWRT_DIR}" <"${FAN_CURVE_PATCH}"
elif patch --dry-run --batch --reverse -p1 -d "${OPENWRT_DIR}" \
        <"${FAN_CURVE_PATCH}" >/dev/null 2>&1; then
    note "The Beryl 7 fan curve patch is already applied"
else
    die "The Beryl 7 fan curve patch is neither applicable nor already applied"
fi

beryl7_dts="${OPENWRT_DIR}/target/linux/mediatek/dts/mt7987a-glinet-gl-mt3600be.dts"
grep -Fqx $'\tcooling-levels = <0 128 176 224 255>;' "${beryl7_dts}" || \
    die "The expected Beryl 7 PWM cooling levels are missing"
for fan_trip in 50000 60000 70000 80000; do
    grep -Fqx $'\t\t\ttemperature = <'"${fan_trip}"'>;' "${beryl7_dts}" || \
        die "The expected Beryl 7 fan trip is missing: ${fan_trip}"
done

note "Installing the Beryl 7 root filesystem defaults"
mkdir -p "${OPENWRT_DIR}/files"
rsync --archive "${FILES_OVERLAY}/" "${OPENWRT_DIR}/files/"
[[ -x "${OPENWRT_DIR}/files/etc/uci-defaults/99-beryl7-luci-ja" ]] || \
    die "The Japanese LuCI first-boot default is not executable"

note "Selecting only the GL.iNET GL-MT3600BE image"
install -m 0644 "${CONFIG_SEED}" "${OPENWRT_DIR}/.config"
make -C "${OPENWRT_DIR}" defconfig

grep -Fqx 'CONFIG_VERSION_CODE="r0+32742-7e35c47c00-beryl7.2"' \
    "${OPENWRT_DIR}/.config" || \
    die "Unexpected firmware version code after make defconfig"
grep -Fqx 'CONFIG_FEED_mtk_openwrt_feed=m' "${OPENWRT_DIR}/.config" || \
    die "The build-only MediaTek feed must be disabled in runtime repositories"
grep -Fqx 'CONFIG_LUCI_LANG_ja=y' "${OPENWRT_DIR}/.config" || \
    die "Japanese must be the selected LuCI language"
for translation_package in \
        luci-i18n-base-ja \
        luci-i18n-firewall-ja \
        luci-i18n-package-manager-ja; do
    translation_symbol="CONFIG_PACKAGE_${translation_package}=y"
    grep -Fqx "${translation_symbol}" "${OPENWRT_DIR}/.config" || \
        die "Japanese LuCI package was not selected: ${translation_package}"
done

for required_package in \
        kmod-tun \
        tailscale \
        kmod-wireguard \
        wireguard-tools \
        luci-proto-wireguard \
        kmod-veth \
        kmod-sched-cake \
        sqm-scripts \
        luci-app-sqm \
        kmod-crypto-eip \
        kmod-crypto-hw-safexcel \
        kmod-nf-flow \
        kmod-nf-flow-netlink \
        kmod-nft-offload \
        netfilter-flowtable \
        mtkhnat_util \
        kmod-ipsec4 \
        kmod-ipsec6 \
        kmod-xfrm-interface \
        kmod-usb-net-rndis \
        kmod-usb-net-cdc-mbim \
        kmod-usb-net-qmi-wwan \
        kmod-usb-net-ipheth \
        usbmuxd \
        libimobiledevice-utils \
        kmod-fs-exfat \
        kmod-fs-ntfs3 \
        kmod-usb-storage-uas \
        block-mount; do
    package_symbol="CONFIG_PACKAGE_${required_package}=y"
    grep -Fqx "${package_symbol}" "${OPENWRT_DIR}/.config" || \
        die "Required package was not selected: ${required_package}"
done

grep -Fqx '# CONFIG_PACKAGE_luci-app-tailscale-community is not set' \
    "${OPENWRT_DIR}/.config" || \
    die "The vulnerable pinned LuCI Tailscale application must remain disabled"

selected_devices="$(
    grep -E '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        "${OPENWRT_DIR}/.config" || true
)"
[[ "${selected_devices}" == \
   'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_glinet_gl-mt3600be=y' ]] || \
    die "Unexpected target selection after make defconfig: ${selected_devices:-none}"

note "Downloading source archives"
make -C "${OPENWRT_DIR}" download -j"${DOWNLOAD_JOBS}"

note "Building firmware with ${JOBS} parallel jobs"
if [[ "${AUTOREMOVE}" == "1" ]]; then
    make -C "${OPENWRT_DIR}" -j"${JOBS}" BUILD_LOG=1 CONFIG_AUTOREMOVE=1
else
    make -C "${OPENWRT_DIR}" -j"${JOBS}" BUILD_LOG=1
fi

target_bin="${OPENWRT_DIR}/bin/targets/mediatek/filogic"
[[ -d "${target_bin}" ]] || die "Target output directory was not created"
[[ -f "${target_bin}/sha256sums" ]] || die "OpenWrt target checksums were not created"

note "Verifying OpenWrt target artifacts"
(
    cd "${target_bin}"
    sha256sum -c sha256sums
)

mapfile -t sysupgrade_images < <(
    find "${target_bin}" -maxdepth 1 -type f \
        -name '*glinet_gl-mt3600be*squashfs-sysupgrade.bin' -print | sort
)
(( ${#sysupgrade_images[@]} == 1 )) || \
    die "Expected exactly one Beryl 7 sysupgrade image, found ${#sysupgrade_images[@]}"

note "Collecting build artifacts"
mkdir -p "${OUTPUT_DIR}"
declare -a collected_artifacts=()
while IFS= read -r -d '' artifact; do
    artifact_name="$(basename -- "${artifact}")"
    install -m 0644 "${artifact}" "${OUTPUT_DIR}/${artifact_name}"
    collected_artifacts+=("${artifact_name}")
done < <(
    find "${target_bin}" -maxdepth 1 -type f \
        \( -name '*glinet_gl-mt3600be*' \
           -o -name '*.manifest' \
           -o -name 'profiles.json' \
           -o -name 'config.buildinfo' \
           -o -name 'feeds.buildinfo' \
           -o -name 'version.buildinfo' \) \
        -print0
)
install -m 0644 "${OPENWRT_DIR}/.config" "${OUTPUT_DIR}/openwrt.config"
collected_artifacts+=("openwrt.config")

# The upstream target checksum file also lists unrelated BL2 images. Publish a
# checksum list containing only the artifacts actually collected above.
(
    cd "${OUTPUT_DIR}"
    for artifact_name in "${collected_artifacts[@]}"; do
        sha256sum "${artifact_name}"
    done
) | sort -k2 >"${OUTPUT_DIR}/SHA256SUMS"

printf '\nBuild complete. Firmware was not flashed.\n'
printf 'Artifacts: %s\n' "${OUTPUT_DIR}"
sha256sum "${sysupgrade_images[0]}"
