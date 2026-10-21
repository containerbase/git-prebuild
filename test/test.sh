#!/bin/bash

# Tests a git archive inside a plain ubuntu container.
# Usage: test.sh <archive> <version>

set -e

ARCHIVE=${1}
VERSION=${2}

CODENAME=$(awk -F= '$1 == "VERSION_CODENAME" { gsub(/"/, "", $2); print $2 }' /etc/os-release)

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

# xz-utils is only needed to extract the archive, python3 for the auth server
PACKAGES+=(ca-certificates libexpat1 libpcre2-8-0 python3 xz-utils zlib1g)

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
# installs or upgrades to the current libcurl, which strips the credentials from the effective url
apt-get install -q -y --no-install-recommends "${PACKAGES[@]}"
dpkg-query -W 'libcurl4*'

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

# a shallow https clone, and a submodule over file://
work=$(mktemp -d)

"${GIT}" clone -q --depth 1 https://github.com/containerbase/git-prebuild "${work}/https"
"${GIT}" -C "${work}/https" log --oneline -1

"${GIT}" init -q "${work}/sub"
"${GIT}" -C "${work}/sub" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m sub
"${GIT}" init -q "${work}/super"
"${GIT}" -C "${work}/super" -c protocol.file.allow=always submodule add -q "file://${work}/sub" sub
"${GIT}" -C "${work}/super" -c user.name=test -c user.email=test@example.com commit -q -m super
"${GIT}" clone -q "file://${work}/super" "${work}/clone"
"${GIT}" -C "${work}/clone" -c protocol.file.allow=always submodule update --init
"${GIT}" -C "${work}/clone" submodule status
if [[ ! -e "${work}/clone/sub/.git" ]]; then
  echo "Submodule not checked out" >&2
  exit 1
fi

# ls-remote and clone over http with a token as user in the url, behind basic auth;
# needs patches/0001-http-handle-curl-stripping-creds-from-effective-url.patch with a libcurl
# that strips the credentials from the effective url
server=$(mktemp -d)
"${GIT}" clone -q --bare "${work}/sub" "${server}/repo.git"
python3 "$(dirname "${BASH_SOURCE[0]}")/auth-server.py" "${GIT}" "${server}" "${server}/port" > "${server}/log" 2>&1 &
server_pid=$!
trap 'kill "${server_pid}"' EXIT

for _ in {1..50}; do
  if [[ -s "${server}/port" ]]; then
    break
  fi
  sleep 0.1
done
if [[ ! -s "${server}/port" ]]; then
  cat "${server}/log"
  echo "Auth server didn't start" >&2
  exit 1
fi

url="http://dummytoken@127.0.0.1:$(< "${server}/port")/repo.git"
failed=false
GIT_TERMINAL_PROMPT=0 "${GIT}" -c credential.helper= ls-remote "${url}" || failed=true
GIT_TERMINAL_PROMPT=0 "${GIT}" -c credential.helper= clone -q "${url}" "${work}/auth" || failed=true
echo "Auth server log:"
cat "${server}/log"
if [[ "${failed}" == "true" ]]; then
  echo "Credentials from the url not used" >&2
  exit 1
fi
if ! grep -q '^POST .* auth=dummytoken:$' "${server}/log"; then
  echo "No POST with the credentials from the url" >&2
  exit 1
fi

kill "${server_pid}"
trap - EXIT
