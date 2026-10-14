# containerbase git releases

[![build](https://github.com/containerbase/git-prebuild/actions/workflows/build.yml/badge.svg)](https://github.com/containerbase/git-prebuild/actions/workflows/build.yml?query=branch%3Amain)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/containerbase/git-prebuild)
![License: MIT](https://img.shields.io/github/license/containerbase/git-prebuild)

Relocatable git builds for [containerbase/base](https://github.com/containerbase/base).

- Built from the [kernel.org tarballs](https://www.kernel.org/pub/software/scm/git/) on Ubuntu `jammy` for `x86_64` and `aarch64`, and used on `jammy`, `noble` and `resolute`.
- Relocatable (`RUNTIME_PREFIX`), system config in `/etc/gitconfig`, no Perl, Python, Tcl/Tk, translations or docs, stripped binaries; see [build options](docs/build-options.md).
- Releases are tagged with the git version and contain `git-<version>-jammy-<arch>.tar.xz` plus a `.sha512` checksum.

Runtime packages:

| Distro              | Packages                                                               |
| ------------------- | ---------------------------------------------------------------------- |
| `jammy`             | `ca-certificates libcurl4 libexpat1 libpcre2-8-0 libssl3 zlib1g`       |
| `noble`, `resolute` | `ca-certificates libcurl4t64 libexpat1 libpcre2-8-0 libssl3t64 zlib1g` |

Before each upload, `binary-builder` runs [`bin/test.sh`](bin/test.sh), which tests the archive in a plain container of each distro.

## Development

Install the linters with `mise install`, then run `jactionlint`, `zizmor .github/` and `shellcheck`.

```bash
# build and pack a version into .cache/
docker build -t builder --build-arg DISTRO=jammy .
docker run --rm -v ${PWD}/.cache:/cache builder 2.56.0

# test the archive on all distros
bin/test.sh .cache/git-2.56.0-jammy-x86_64.tar.xz 2.56.0
```

Optional: `APT_PROXY` (build arg) for an apt proxy, `DEBUG=true` (run env) for verbose make output, `DOCKER_RUN_ARGS` for extra `docker run` arguments in `bin/test.sh` (e.g. `--network=host`).
