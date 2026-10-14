#-------------------------
# renovate rebuild trigger
# Check:
# - https://github.com/git/git/tags
# - https://www.kernel.org/pub/software/scm/git/
#-------------------------

# makes lint happy
FROM scratch

# renovate: datasource=github-tags depName=git packageName=git/git
ENV GIT_VERSION=2.56.0
