#--------------------------------------
# Ubuntu flavor
#--------------------------------------
ARG DISTRO=noble

#--------------------------------------
# base images
#--------------------------------------
FROM ghcr.io/containerbase/ubuntu:24.04@sha256:73b999393d07f2bf65a40373778a44dc9a6d54ad7718d29247d8ff9413c4d6a8 AS build-noble


#--------------------------------------
# builder images
#--------------------------------------
FROM build-${DISTRO} AS builder


ENTRYPOINT [ "dumb-init", "--", "builder.sh" ]

COPY bin /usr/local/bin

RUN install-builder.sh

COPY make-options.txt /usr/local/share/git-prebuild/
COPY patches /usr/local/share/git-prebuild/patches
