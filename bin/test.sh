#!/bin/bash

# Tests a git archive on all supported distros with the host architecture.
# binary-builder calls it after each build: test.sh <archive> <version>
# Extra `docker build` arguments can be passed with DOCKER_BUILD_ARGS,
# e.g. `DOCKER_BUILD_ARGS=--network=host` when the docker DNS doesn't work locally.

set -e

if [[ $# -ne 2 || ! -f "${1}" ]]; then
  echo "Usage: test.sh <archive> <version>" >&2
  exit 1
fi

ARCHIVE=$(realpath "${1}")
VERSION=${2}
DISTROS=(jammy noble resolute)
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/test"

read -r -a docker_args <<< "${DOCKER_BUILD_ARGS}"

failed=()
for distro in "${DISTROS[@]}"; do
  echo "Testing $(basename "${ARCHIVE}") on ${distro}"
  if ! docker build \
    --progress plain \
    --no-cache \
    "${docker_args[@]}" \
    --build-arg "DISTRO=${distro}" \
    --build-arg "ARCHIVE=$(basename "${ARCHIVE}")" \
    --build-arg "VERSION=${VERSION}" \
    --build-context "archive=$(dirname "${ARCHIVE}")" \
    "${TEST_DIR}"; then
    failed+=("${distro}")
  fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
  echo "Tests failed on: ${failed[*]}" >&2
  exit 1
fi

echo "Tests passed on: ${DISTROS[*]}"
