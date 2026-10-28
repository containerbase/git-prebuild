# Build options

[`bin/builder.sh`](../bin/builder.sh) builds git with `make all install` and these variables:

| Variable                          | Why                                                                                                                                                                                           |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prefix=/usr/local/git/<version>` | install prefix, the archive contains the `<version>` folder                                                                                                                                   |
| `sysconfdir=/etc`                 | the system config stays `/etc/gitconfig`, an absolute path is kept with `RUNTIME_PREFIX`                                                                                                      |
| `RUNTIME_PREFIX=YesPlease`        | relocatable, git finds `libexec/git-core` relative to its binary                                                                                                                              |
| `NO_TCLTK=YesPlease`              | no `gitk` and `git gui`                                                                                                                                                                       |
| `NO_GETTEXT=YesPlease`            | no translations                                                                                                                                                                               |
| `NO_INSTALL_HARDLINKS=YesPlease`  | no hard links between the installed binaries                                                                                                                                                  |
| `INSTALL_SYMLINKS=YesPlease`      | the built-ins in `libexec/git-core` are relative symlinks, so the archive stays small and relocatable                                                                                         |
| `USE_LIBPCRE2=YesPlease`          | perl compatible regular expressions for `git grep -P` and `log -P`                                                                                                                            |
| `NO_PERL=YesPlease`               | no perl scripts (`send-email`, `svn`, `cvs*`, `archimport`), none of them is used by Renovate or the tools containerbase installs; needs git ≥ 2.37, where `add -i`/`add -p` are C by default |
| `NO_PYTHON=YesPlease`             | no python scripts                                                                                                                                                                             |
| `NO_OPENSSL=YesPlease`            | no direct OpenSSL dependency, see [TLS](#tls)                                                                                                                                                 |

The binaries are stripped after `make install`.

`NO_RUST` is not set, so git builds its Rust code (`libgitcore`, which replaces some C implementations) with the Rust toolchain that [`bin/install-builder.sh`](../bin/install-builder.sh) installs in the builder image from the official standalone installer.
The toolchain is only used for the build, the archive has no new runtime dependencies.
Rust is on by default since git 2.55; 2.52 to 2.54 only build it with `WITH_RUST`, which isn't set, so like older versions they are built without Rust.

`SKIP_DASHED_BUILT_INS` is not set: local transports (`file://` URLs, `git fetch /path`, local submodules) start the dashed `git-upload-pack` from `libexec/git-core`, which that option removes.

## TLS

git is built against the GnuTLS flavour of libcurl (`libcurl4-gnutls-dev`), like Ubuntu's git package, and with `NO_OPENSSL`, so https and `imap-send` go through libcurl with GnuTLS.
Ubuntu's OpenSSL switches to its FIPS provider when the kernel is in FIPS mode (`/proc/sys/crypto/fips_enabled` is `1`), but that provider is only shipped with Ubuntu Pro, so with the OpenSSL libcurl every https request fails with `Insufficient randomness` on FIPS hosts.
The test in [`test/test.sh`](../test/test.sh) runs `ls-remote` over https with `OPENSSL_FIPS_MODE_SWITCH_PATH` pointing to a file with `1`, which makes Ubuntu's OpenSSL behave as on a FIPS host.

## Patches

Before the build, [`bin/builder.sh`](../bin/builder.sh) applies the upstream fixes from [`patches/`](../patches) in name order.
A patch the source already contains (its reverse applies) is skipped with an `already included` message, so it stays until the oldest built version contains it; a patch that doesn't apply fails the build.
Files that are already published aren't rebuilt, only new versions get the patches. The `noble` files are built for every release, so they all have the patches; the older `jammy` files don't.

- [`0001-http-handle-curl-stripping-creds-from-effective-url.patch`](../patches/0001-http-handle-curl-stripping-creds-from-effective-url.patch): git commit [`76524c2604bc`](https://github.com/git/git/commit/76524c2604bc), not in git 2.56.0.
  curl ≥ 8.23.0 and the Ubuntu security updates of curl (`8.5.0-2ubuntu10.16` on `noble`, `8.18.0-1ubuntu2.8` on `resolute`) strip the credentials from `CURLINFO_EFFECTIVE_URL`.
  Without the fix git takes that for a redirect and drops the credentials, so http remotes with credentials in the url, like `https://<token>@host/repo.git`, send the following requests without them and fail.
  The test in [`test/test.sh`](../test/test.sh) runs `ls-remote` and `clone` with `http://dummytoken@127.0.0.1:<port>/repo.git` against a basic auth server ([`test/auth-server.py`](../test/auth-server.py) in front of the prebuild's `git http-backend`) with the current libcurl of each distro, and checks that the `POST` requests carry the credentials.

## New git versions

`binary-builder` builds every git release from `startVersion` up to the newest approved minor (`"allowedVersions": "<=2.56"` in [`builder.json`](../builder.json)), so new patches of approved minors are built on `main` without a PR.
`startVersion` is `2.48.0`, the oldest minor git still backports security fixes to; older requested versions fall back to the newest prebuild in containerbase.
For a new minor, Renovate opens one PR per minor that bumps that bound, two hours after its release so the kernel.org tarball is published; when the PR can't automerge (e.g. the build fails on new make options), Renovate assigns the maintainer.
The PR build only builds the newest version in the bound, and [`bin/builder.sh`](../bin/builder.sh) compares the `# Define` options of its `Makefile` with [`make-options.txt`](../make-options.txt) before `make`: new options fail the build, options missing in an older version only print a warning.
To approve a new minor, check the new options, enable the useful ones in `bin/builder.sh`, and add them to `make-options.txt`; the build writes the full list of the version to `.cache/make-options-<version>.txt`.
