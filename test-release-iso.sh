#!/usr/bin/env bash

set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${repo_root}"

# Usage: ./test-release-iso.sh [image-ref]
# Default image ref expects a published image that matches disk_config/iso.toml.
image_ref="${1:-${IMAGE_REF:-ghcr.io/rishondev/reviveos:latest}}"
bib_image="${BIB_IMAGE:-quay.io/centos-bootc/bootc-image-builder:latest}"
config_path="${BIB_CONFIG:-${repo_root}/disk_config/iso.toml}"
output_dir="${BIB_OUTPUT_DIR:-${repo_root}/output-local}"
ghcr_user="${GHCR_USERNAME:-${GITHUB_ACTOR:-}}"
terra_key_file="$(mktemp "${TMPDIR:-/tmp}/reviveos-terra-key.XXXXXX")"
iso_config_file="$(mktemp "${TMPDIR:-/tmp}/reviveos-iso-config.XXXXXX")"

cleanup() {
    rm -f "${terra_key_file}"
    rm -f "${iso_config_file}"
}
trap cleanup EXIT

mkdir -p "${output_dir}"
sed "s|ghcr.io/rishondev/reviveos:latest|${image_ref}|g" "${config_path}" > "${iso_config_file}"
curl -fsSL https://repos.fyralabs.com/terra43-mesa/key.asc -o "${terra_key_file}"
printf 'Building ISO from %s\n' "${image_ref}"

if [[ "${image_ref}" == ghcr.io/* && -n "${GITHUB_TOKEN:-}" && -n "${ghcr_user}" ]]; then
    printf '%s' "${GITHUB_TOKEN}" | sudo podman login ghcr.io \
        --username "${ghcr_user}" \
        --password-stdin
fi

sudo podman pull "${image_ref}"

sudo podman run \
    --rm \
    --privileged \
    --pull=newer \
    -v "${iso_config_file}:/config.toml:ro" \
    -v "${output_dir}:/output" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v "${terra_key_file}:/etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa:ro" \
    "${bib_image}" \
    --type iso \
    --chown "$(id -u):$(id -g)" \
    --use-librepo=True \
    --rootfs=btrfs \
    "${image_ref}"

find "${output_dir}" -name '*.iso' -print
