#!/bin/bash

set -e

VERSION=${1}

CODENAME=$(awk -F= '$1 == "VERSION_CODENAME" { gsub(/"/, "", $2); print $2 }' /etc/os-release)

NAME=git
ARCH=$(uname -p)
BUILD_ARGS=()

if [[ "${DEBUG}" == "true" ]]; then
  BUILD_ARGS+=("V=1")
fi

PREFIX="/usr/local/${NAME}/${VERSION}"
BASE_URL="https://www.kernel.org/pub/software/scm/git"
FILE="${NAME}-${VERSION}.tar.xz"
SRC_DIR=$(mktemp -d)

MAKE_ARGS=(
  "prefix=${PREFIX}"
  "sysconfdir=/etc"
  "RUNTIME_PREFIX=YesPlease"
  "NO_TCLTK=YesPlease"
  "NO_GETTEXT=YesPlease"
  "NO_INSTALL_HARDLINKS=YesPlease"
  "INSTALL_SYMLINKS=YesPlease"
  "USE_LIBPCRE2=YesPlease"
  "NO_PERL=YesPlease"
  "NO_PYTHON=YesPlease"
)

echo "Downloading ${NAME} ${VERSION}"
curl -fsSL -o "${SRC_DIR}/${FILE}" "${BASE_URL}/${FILE}"
curl -fsSL -o "${SRC_DIR}/sha256sums.asc" "${BASE_URL}/sha256sums.asc"

pushd "${SRC_DIR}" > /dev/null
awk -v file="${FILE}" '$2 == file' sha256sums.asc | sha256sum -c --strict -
tar -xf "${FILE}"
pushd "${NAME}-${VERSION}" > /dev/null

echo "Building ${NAME} ${VERSION} for ${CODENAME}-${ARCH}"
make -j "$(nproc)" "${BUILD_ARGS[@]}" "${MAKE_ARGS[@]}" all
make "${BUILD_ARGS[@]}" "${MAKE_ARGS[@]}" install

popd > /dev/null
popd > /dev/null

echo "Stripping ${NAME} ${VERSION} binaries"
while IFS= read -r -d '' file; do
  if [[ "$(head -c 4 "${file}")" == $'\x7fELF' ]]; then
    strip "${file}"
  fi
done < <(find "${PREFIX}/bin" "${PREFIX}/libexec/git-core" -type f -print0)

# check that `git --version` matches and the exec path is inside the given prefix
function check_git () {
  local prefix=${1}
  local actual exec_path

  actual=$("${prefix}/bin/git" --version)
  echo "${actual}"
  if [[ "${actual}" != "git version ${VERSION}" ]]; then
    echo "Unexpected version: ${actual}" >&2
    exit 1
  fi

  exec_path=$("${prefix}/bin/git" --exec-path)
  echo "exec-path: ${exec_path}"
  if [[ "${exec_path}" != "${prefix}/"* ]]; then
    echo "Exec path outside of ${prefix}: ${exec_path}" >&2
    exit 1
  fi
}

# check a shallow https clone, and a submodule over file://
function check_clone () {
  local work
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

  rm -rf "${work}"
}

echo "Testing ${NAME} ${VERSION} for ${CODENAME}-${ARCH}"
GIT="${PREFIX}/bin/git"

check_git "${PREFIX}"

printf '[containerbase]\n\ttest = true\n' > /etc/gitconfig
"${GIT}" config --system --show-origin --list
if ! "${GIT}" config --system --list | grep -qx 'containerbase.test=true'; then
  echo "System config not read from /etc/gitconfig" >&2
  exit 1
fi
rm -f /etc/gitconfig

repo=$(mktemp -d)
"${GIT}" init -q "${repo}"
"${GIT}" -C "${repo}" -c safe.directory='*' status

"${GIT}" ls-remote https://github.com/git/git HEAD
check_clone

echo "Libexec entries: $(find "${PREFIX}/libexec/git-core" -mindepth 1 -maxdepth 1 | wc -l)"

echo "Testing relocated ${NAME} ${VERSION}"
relocated="$(mktemp -d)/relocated"
cp -a "${PREFIX}" "${relocated}"
check_git "${relocated}"
rm -rf "${relocated}"

echo "Compressing ${NAME} ${VERSION} for ${CODENAME}-${ARCH}"
tar -cJf "/cache/${NAME}-${VERSION}-${CODENAME}-${ARCH}.tar.xz" -C /usr/local/${NAME} "${VERSION}"
