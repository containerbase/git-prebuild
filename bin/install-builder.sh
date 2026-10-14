#!/bin/bash

set -e


echo "APT::Install-Recommends \"false\";" | tee -a /etc/apt/apt.conf.d/99buildpack.conf
echo "APT::Get::Upgrade \"false\";" | tee -a /etc/apt/apt.conf.d/99buildpack.conf
echo "APT::Get::Install-Suggests \"false\";" | tee -a /etc/apt/apt.conf.d/99buildpack.conf

if [[ -n "${APT_PROXY}" ]]; then
  echo "Acquire::http::proxy \"${APT_PROXY}\";" | tee -a /etc/apt/apt.conf.d/99buildpack-proxy.conf
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -q
apt-get install -q -y \
  build-essential \
  ca-certificates \
  curl \
  dumb-init \
  libcurl4-openssl-dev \
  libexpat1-dev \
  libpcre2-dev \
  libssl-dev \
  zlib1g-dev \
  ;

#--------------------------------
# rust toolchain, only used for the build
#--------------------------------
# renovate: datasource=github-releases depName=rust packageName=rust-lang/rust
RUST_VERSION=1.90.0

RUST_TARGET="$(uname -m)-unknown-linux-gnu"
RUST_FILE="rust-${RUST_VERSION}-${RUST_TARGET}.tar.xz"
RUST_DIR=$(mktemp -d)

curl -fsSL -o "${RUST_DIR}/${RUST_FILE}" "https://static.rust-lang.org/dist/${RUST_FILE}"
curl -fsSL -o "${RUST_DIR}/${RUST_FILE}.sha256" "https://static.rust-lang.org/dist/${RUST_FILE}.sha256"

pushd "${RUST_DIR}" > /dev/null
sha256sum -c --strict "${RUST_FILE}.sha256"
tar -xf "${RUST_FILE}"
"./rust-${RUST_VERSION}-${RUST_TARGET}/install.sh" \
  --prefix=/usr/local \
  --components="rustc,cargo,rust-std-${RUST_TARGET}" \
  --disable-ldconfig
popd > /dev/null
rm -rf "${RUST_DIR}"

cargo --version
rustc --version

mkdir -p /usr/local/git /cache

#--------------------------------
# cleanup
#--------------------------------
if [[ -n "${APT_PROXY}" ]]; then
  rm -f /etc/apt/apt.conf.d/99buildpack-proxy.conf
fi
