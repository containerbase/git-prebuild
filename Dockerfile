#--------------------------------------
# Ubuntu flavor
#--------------------------------------
ARG DISTRO=noble

#--------------------------------------
# base images
#--------------------------------------
FROM ghcr.io/containerbase/ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852 AS build-noble


#--------------------------------------
# builder images
#--------------------------------------
FROM build-${DISTRO} AS builder


ENTRYPOINT [ "dumb-init", "--", "builder.sh" ]

COPY bin /usr/local/bin

RUN install-builder.sh

COPY make-options.txt /usr/local/share/git-prebuild/
COPY patches /usr/local/share/git-prebuild/patches
