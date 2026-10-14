# containerbase git releases

[![build](https://github.com/containerbase/git-prebuild/actions/workflows/build.yml/badge.svg)](https://github.com/containerbase/git-prebuild/actions/workflows/build.yml?query=branch%3Amain)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/containerbase/git-prebuild)
![License: MIT](https://img.shields.io/github/license/containerbase/git-prebuild)

Prebuild relocatable git releases used by [containerbase/base](https://github.com/containerbase/base).

git is built from the official [kernel.org tarballs](https://www.kernel.org/pub/software/scm/git/), verified against `sha256sums.asc`, with these `make` options:

| Option                           | Description                                                  |
| -------------------------------- | ------------------------------------------------------------ |
| `RUNTIME_PREFIX=YesPlease`       | relocatable, finds `libexec/git-core` relative to the binary |
| `sysconfdir=/etc`                | system config stays `/etc/gitconfig`                         |
| `NO_TCLTK=YesPlease`             | no `gitk` and `git gui`                                      |
| `NO_GETTEXT=YesPlease`           | no translations                                              |
| `NO_PYTHON=YesPlease`            | no python scripts                                            |
| `NO_INSTALL_HARDLINKS=YesPlease` | no hard links between installed binaries                     |
| `INSTALL_SYMLINKS=YesPlease`     | builtins are installed as relative symlinks                  |
| `USE_LIBPCRE2=YesPlease`         | perl compatible regular expressions                          |

git is linked against the distro's `libcurl` (OpenSSL flavour), `zlib`, `expat` and `libpcre2`.
No documentation is built and the binaries are stripped.

git is built on Ubuntu `jammy` for `x86_64` and `aarch64`, and the same build is used on `jammy`, `noble` and `resolute`.
CI tests the archives on all three distros with [`bin/test.sh`](bin/test.sh).
A target needs these runtime packages:

| Distro              | Packages                                                               |
| ------------------- | ---------------------------------------------------------------------- |
| `jammy`             | `ca-certificates libcurl4 libexpat1 libpcre2-8-0 libssl3 zlib1g`       |
| `noble`, `resolute` | `ca-certificates libcurl4t64 libexpat1 libpcre2-8-0 libssl3t64 zlib1g` |

`libexpat1` is only linked by `git http-push`, `libssl3` directly only by `git imap-send` (`libcurl` needs it anyway).

Releases are tagged with the plain git version (eg. `2.33.0`) and contain a `git-<version>-<distro>-<arch>.tar.xz` archive plus a `.sha512` checksum for each build.

## Local development

Build the image

```bash
docker build -t builder --build-arg APT_PROXY=http://apt-proxy:3142 --build-arg DISTRO=jammy .
```

Test the image

```bash
docker run --rm -it -v ${PWD}/.cache:/cache -e DEBUG=true builder 2.33.0
```

`${PWD}/.cache` will contain packed releases after successful build.

Test a packed release on another distro

```bash
docker run --rm -v ${PWD}:/work -w /work ghcr.io/containerbase/ubuntu:24.04 bin/test.sh .cache/git-2.33.0-jammy-x86_64.tar.xz
```

Optional environment variables

| Name        | Description                                          | Default   |
| ----------- | ---------------------------------------------------- | --------- |
| `DISTRO`    | Set an ubuntu base distro, only `jammy` is supported | `jammy`   |
| `APT_PROXY` | Set an APT http proxy for installing build deps      | `<empty>` |
| `DEBUG`     | Show verbose git build output                        | `<empty>` |
