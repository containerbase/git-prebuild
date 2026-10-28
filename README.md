# containerbase git releases

[![build](https://github.com/containerbase/git-prebuild/actions/workflows/build.yml/badge.svg)](https://github.com/containerbase/git-prebuild/actions/workflows/build.yml?query=branch%3Amain)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/containerbase/git-prebuild)
![License: MIT](https://img.shields.io/github/license/containerbase/git-prebuild)

Relocatable git builds for [containerbase/base](https://github.com/containerbase/base).

- Built from the [kernel.org tarballs](https://www.kernel.org/pub/software/scm/git/) on Ubuntu `noble` for `x86_64` and `aarch64`, and used on `noble` and `resolute`.
- Relocatable (`RUNTIME_PREFIX`), system config in `/etc/gitconfig`, no Perl, Python, Tcl/Tk, translations or docs, stripped binaries; see [build options](docs/build-options.md).
- Upstream fixes from [`patches/`](patches) are applied when the git version doesn't contain them yet; see [patches](docs/build-options.md#patches).
- Every git release since `2.48.0` is built, the oldest minor git still backports security fixes to; containerbase falls back to the newest prebuild for older versions.
- Releases are tagged with the git version and contain `git-<version>-noble-<arch>.tar.xz` plus a `.sha512` checksum. The `jammy` files of older releases are kept but no longer built.

Runtime packages:

| Distro              | Packages                                                           |
| ------------------- | ------------------------------------------------------------------ |
| `noble`, `resolute` | `ca-certificates libcurl3t64-gnutls libexpat1 libpcre2-8-0 zlib1g` |

Before each upload, `binary-builder` runs [`bin/test.sh`](bin/test.sh), which tests the archive in a plain container of each distro, including a clone with credentials in the url against a local basic auth server.

## Development

Install the linters with `mise install`, then run `jactionlint`, `zizmor .github/` and `shellcheck`; the pre-commit hook runs them on the staged files too.

```bash
# build and pack a version into .cache/
docker build -t builder --build-arg DISTRO=noble .
docker run --rm -v ${PWD}/.cache:/cache builder 2.56.0

# test the archive on all distros
bin/test.sh .cache/git-2.56.0-noble-x86_64.tar.xz 2.56.0
```

Optional: `APT_PROXY` (build arg) for an apt proxy, `DEBUG=true` (run env) for verbose make output, `DOCKER_RUN_ARGS` for extra `docker run` arguments in `bin/test.sh` (e.g. `--network=host`).
