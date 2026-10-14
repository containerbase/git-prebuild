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

The binaries are stripped after `make install`.

`NO_RUST` is not set, so git builds its Rust code (`libgitcore`, which replaces some C implementations) with the Rust toolchain that [`bin/install-builder.sh`](../bin/install-builder.sh) installs in the builder image from the official standalone installer.
The toolchain is only used for the build, the archive has no new runtime dependencies.

`SKIP_DASHED_BUILT_INS` is not set: local transports (`file://` URLs, `git fetch /path`, local submodules) start the dashed `git-upload-pack` from `libexec/git-core`, which that option removes.

## New git versions

`binary-builder` builds every git release from `startVersion` up to the newest approved minor (`"allowedVersions": "<=2.56"` in [`builder.json`](../builder.json)), so new patches of approved minors are built on `main` without a PR.
For a new minor, Renovate opens one PR per minor that bumps that bound and asks @viceice for a review.
The PR build only builds the newest version in the bound, and [`bin/builder.sh`](../bin/builder.sh) compares the `# Define` options of its `Makefile` with [`make-options.txt`](../make-options.txt) before `make`: new options fail the build, options missing in an older version only print a warning.
To approve a new minor, check the new options, enable the useful ones in `bin/builder.sh`, and add them to `make-options.txt`; the build writes the full list of the version to `.cache/make-options-<version>.txt`.
