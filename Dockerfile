#--------------------------------------
# Ubuntu flavor
#--------------------------------------
ARG DISTRO=noble

#--------------------------------------
# base images
#--------------------------------------
FROM ghcr.io/containerbase/ubuntu:24.04@sha256:2198e4c65076e9cb0b3d695219df667c0e3b0072da64ca3c2648aca17dcecaf5 AS build-noble


#--------------------------------------
# builder images
#--------------------------------------
FROM build-${DISTRO} AS builder


ENTRYPOINT [ "dumb-init", "--", "builder.sh" ]

COPY bin /usr/local/bin

RUN install-builder.sh

COPY make-options.txt /usr/local/share/git-prebuild/
COPY patches /usr/local/share/git-prebuild/patches
