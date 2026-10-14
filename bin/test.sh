#!/bin/bash

# Tests git archives on a plain ubuntu container.
# Usage: test.sh <archive>...

set -e

# shellcheck disable=SC1091
CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME}")

NAME=git
ARCH=$(uname -m)
FILE_REGEX="^${NAME}-([0-9]+\.[0-9]+\.[0-9]+)-.+\.tar\.xz$"

if [[ $# -eq 0 ]]; then
  echo "Missing archive argument" >&2
  exit 1
fi

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

# xz-utils is only needed to extract the archives
PACKAGES+=(ca-certificates libexpat1 libpcre2-8-0 xz-utils zlib1g)

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -q -y --no-install-recommends "${PACKAGES[@]}"

mkdir -p "/usr/local/${NAME}"

for archive in "$@"; do
  if [[ ! "$(basename "${archive}")" =~ ${FILE_REGEX} ]]; then
    echo "Unexpected archive name: ${archive}" >&2
    exit 1
  fi
  VERSION=${BASH_REMATCH[1]}
  PREFIX="/usr/local/${NAME}/${VERSION}"
  GIT="${PREFIX}/bin/git"

  echo "Testing ${NAME} ${VERSION} on ${CODENAME}-${ARCH}"
  tar -xf "${archive}" -C "/usr/local/${NAME}"

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
done
