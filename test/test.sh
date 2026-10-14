#!/bin/bash

# Tests a git archive inside a plain ubuntu container.
# Usage: test.sh <archive> <version>

set -e

ARCHIVE=${1}
VERSION=${2}

# shellcheck disable=SC1091
CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME}")

NAME=git
ARCH=$(uname -m)
PREFIX="/usr/local/${NAME}/${VERSION}"
GIT="${PREFIX}/bin/git"

case "${CODENAME}" in
  jammy)
    PACKAGES=(libcurl4 libssl3)
    ;;
  noble|resolute)
    PACKAGES=(libcurl4t64 libssl3t64)
    ;;
  *)
    echo "Unsupported distro: ${CODENAME}" >&2
    exit 1
    ;;
esac

# xz-utils is only needed to extract the archive
PACKAGES+=(ca-certificates libexpat1 libpcre2-8-0 xz-utils zlib1g)

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -q -y --no-install-recommends "${PACKAGES[@]}"

echo "Testing ${NAME} ${VERSION} on ${CODENAME}-${ARCH}"
mkdir -p "/usr/local/${NAME}"
tar -xf "${ARCHIVE}" -C "/usr/local/${NAME}"

for file in \
  "${GIT}" \
  "${PREFIX}/libexec/git-core/git-remote-https" \
  "${PREFIX}/libexec/git-core/git-http-push" \
  "${PREFIX}/libexec/git-core/git-imap-send"; do
  echo "ldd ${file}"
  ldd "${file}"
  if ldd "${file}" | grep -q 'not found'; then
    echo "Missing libraries for ${file}" >&2
    exit 1
  fi
done

actual=$("${GIT}" --version)
echo "${actual}"
if [[ "${actual}" != "git version ${VERSION}" ]]; then
  echo "Unexpected version: ${actual}" >&2
  exit 1
fi

exec_path=$("${GIT}" --exec-path)
echo "exec-path: ${exec_path}"
if [[ "${exec_path}" != "${PREFIX}/"* ]]; then
  echo "Exec path outside of ${PREFIX}: ${exec_path}" >&2
  exit 1
fi

repo=$(mktemp -d)
"${GIT}" init -q "${repo}"
"${GIT}" -C "${repo}" -c safe.directory='*' status

"${GIT}" ls-remote https://github.com/git/git HEAD
