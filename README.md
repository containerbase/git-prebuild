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
A target needs these runtime packages:

| Distro              | Packages                                                               |
| ------------------- | ---------------------------------------------------------------------- |
| `jammy`             | `ca-certificates libcurl4 libexpat1 libpcre2-8-0 libssl3 zlib1g`       |
| `noble`, `resolute` | `ca-certificates libcurl4t64 libexpat1 libpcre2-8-0 libssl3t64 zlib1g` |

`libexpat1` is only linked by `git http-push`, `libssl3` directly only by `git imap-send` (`libcurl` needs it anyway).

Releases are tagged with the plain git version (eg. `2.33.0`) and contain a `git-<version>-<distro>-<arch>.tar.xz` archive plus a `.sha512` checksum for each build.

## Tests

`builder.json` registers [`bin/test.sh`](bin/test.sh) as the `binary-builder` test hook.
After each build, and before the checksum and the upload, `binary-builder` runs `bin/test.sh <archive> <version>` on the runner, also for pull requests.
It builds [`test/Dockerfile`](test/Dockerfile) for `jammy`, `noble` and `resolute` with the runner's architecture, which runs [`test/test.sh`](test/test.sh) in a plain container of each distro: it installs the runtime packages, extracts the archive and checks the linked libraries, `git --version`, `git --exec-path`, `git status` and `git ls-remote` over https.
A failing distro fails the version, so nothing is uploaded.

The hook needs a `containerbase/internal-tools` release that includes [containerbase/internal-tools#2499](https://github.com/containerbase/internal-tools/pull/2499).
Until the action pin in the workflow is bumped to such a release, the tests don't run in CI.

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

Test a packed release on all distros

```bash
bin/test.sh .cache/git-2.33.0-jammy-x86_64.tar.xz 2.33.0
```

Pass extra `docker build` arguments with `DOCKER_BUILD_ARGS`, eg. `DOCKER_BUILD_ARGS=--network=host` when the docker DNS doesn't work.

Optional environment variables

| Name        | Description                                          | Default   |
| ----------- | ---------------------------------------------------- | --------- |
| `DISTRO`    | Set an ubuntu base distro, only `jammy` is supported | `jammy`   |
| `APT_PROXY` | Set an APT http proxy for installing build deps      | `<empty>` |
| `DEBUG`     | Show verbose git build output                        | `<empty>` |
