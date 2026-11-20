#--------------------------------------
# Ubuntu flavor
#--------------------------------------
ARG DISTRO=noble

#--------------------------------------
# base images
#--------------------------------------
FROM ghcr.io/containerbase/ubuntu:24.04@sha256:ab18ecc70c55c703eae968948f9f1dbbe662aa8d9badac7c982e6a6237b9d74c AS build-noble


#--------------------------------------
# builder images
#--------------------------------------
FROM build-${DISTRO} AS builder


ENTRYPOINT [ "dumb-init", "--", "builder.sh" ]

COPY bin /usr/local/bin

RUN install-builder.sh

COPY make-options.txt /usr/local/share/git-prebuild/
COPY patches /usr/local/share/git-prebuild/patches
