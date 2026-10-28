#--------------------------------------
# Ubuntu flavor
#--------------------------------------
ARG DISTRO=noble

#--------------------------------------
# base images
#--------------------------------------
FROM ghcr.io/containerbase/ubuntu:24.04@sha256:68ee22004a9109b44973313b02ff7b1de250f1de0f5ecb628d73f579aaff33ac AS build-noble


#--------------------------------------
# builder images
#--------------------------------------
FROM build-${DISTRO} AS builder


ENTRYPOINT [ "dumb-init", "--", "builder.sh" ]

COPY bin /usr/local/bin

RUN install-builder.sh

COPY make-options.txt /usr/local/share/git-prebuild/
COPY patches /usr/local/share/git-prebuild/patches
