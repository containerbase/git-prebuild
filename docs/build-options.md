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
| `NO_RUST=YesPlease`               | Rust is optional until git 3.0, so the build needs no Cargo toolchain; the C implementations are used                                                                                         |

The binaries are stripped after `make install`.

`SKIP_DASHED_BUILT_INS` is not set: local transports (`file://` URLs, `git fetch /path`, local submodules) start the dashed `git-upload-pack` from `libexec/git-core`, which that option removes.
