#!/bin/bash

# Tests a git archive on all supported distros with the host architecture.
# binary-builder calls it after each build: test.sh <archive> <version>
# Extra `docker run` arguments can be passed with DOCKER_RUN_ARGS,
# e.g. `DOCKER_RUN_ARGS=--network=host` when the docker DNS doesn't work locally.

set -e

if [[ $# -ne 2 || ! -f "${1}" ]]; then
  echo "Usage: test.sh <archive> <version>" >&2
  exit 1
fi

ARCHIVE=$(realpath "${1}")
VERSION=${2}
DISTROS=(jammy noble resolute)
declare -A RELEASES=([jammy]=22.04 [noble]=24.04 [resolute]=26.04)
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/test"

read -r -a docker_args <<< "${DOCKER_RUN_ARGS}"

failed=()
for distro in "${DISTROS[@]}"; do
  echo "Testing $(basename "${ARCHIVE}") on ${distro}"
  if ! docker run \
    --rm \
    --pull always \
    "${docker_args[@]}" \
    --volume "$(dirname "${ARCHIVE}"):/archive:ro" \
    --volume "${TEST_DIR}:/test:ro" \
    "ghcr.io/containerbase/ubuntu:${RELEASES[${distro}]}" \
    /test/test.sh "/archive/$(basename "${ARCHIVE}")" "${VERSION}"; then
    failed+=("${distro}")
  fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
  echo "Tests failed on: ${failed[*]}" >&2
  exit 1
fi

echo "Tests passed on: ${DISTROS[*]}"
