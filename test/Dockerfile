#--------------------------------------
# Ubuntu flavor
#--------------------------------------
ARG DISTRO=jammy

#--------------------------------------
# test images
#--------------------------------------
FROM ghcr.io/containerbase/ubuntu:22.04@sha256:5ec03bb3441e8b0bf3b4f9cd4629a1ae763010dc3035bb8da3ae6cf026486401 AS jammy
FROM ghcr.io/containerbase/ubuntu:24.04@sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55 AS noble
FROM ghcr.io/containerbase/ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7 AS resolute


#--------------------------------------
# test
#--------------------------------------
FROM ${DISTRO}

# archive file name in the `archive` build context and its git version
ARG ARCHIVE
ARG VERSION

COPY --chmod=755 test.sh /usr/local/bin/test.sh
COPY --from=archive ${ARCHIVE} /tmp/git.tar.xz

RUN test.sh /tmp/git.tar.xz "${VERSION}"
