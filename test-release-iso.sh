#!/usr/bin/env bash

set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${repo_root}"

# Usage: ./test-release-iso.sh [image-ref]
# Default image ref expects a local image built with:
#   just build localhost/reviveos latest
image_ref="${1:-${IMAGE_REF:-localhost/reviveos:latest}}"
image_type="${2:-${IMAGE_TYPE:-qcow2}}"
bib_image="${BIB_IMAGE:-quay.io/centos-bootc/bootc-image-builder:latest}"
output_dir="${BIB_OUTPUT_DIR:-${repo_root}/output-local}"
ghcr_user="${GHCR_USERNAME:-${GITHUB_ACTOR:-}}"
terra_key_file="$(mktemp "${TMPDIR:-/tmp}/reviveos-terra-key.XXXXXX")"
build_config_file="$(mktemp "${TMPDIR:-/tmp}/reviveos-build-config.XXXXXX")"

cleanup() {
    rm -f "${terra_key_file}"
    rm -f "${build_config_file}"
}
trap cleanup EXIT

mkdir -p "${output_dir}"
case "${image_type}" in
    iso)
        sed "s|__IMAGE_REF__|${image_ref}|g" "${repo_root}/disk_config/iso.toml" > "${build_config_file}"
        ;;
    qcow2|raw)
        cp "${repo_root}/disk_config/disk.toml" "${build_config_file}"
        ;;
    *)
        echo "Unsupported image type: ${image_type}" >&2
        exit 1
        ;;
esac

curl -fsSL https://repos.fyralabs.com/terra43-mesa/key.asc -o "${terra_key_file}"
printf 'Building %s from %s\n' "${image_type}" "${image_ref}"

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
    -v "${build_config_file}:/config.toml:ro" \
    -v "${output_dir}:/output" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v "${terra_key_file}:/etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa:ro" \
    "${bib_image}" \
    --type "${image_type}" \
    --chown "$(id -u):$(id -g)" \
    --use-librepo=True \
    --rootfs=btrfs \
    "${image_ref}"

find "${output_dir}" -type f -print
