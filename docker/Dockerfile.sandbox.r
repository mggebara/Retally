# openra-sandbox-r
#
# Offline execution environment for ML / econometrics reproduction
# code written in R.  Built on Rocker's r2u image, which provides
# fast binary package installation from CRAN via apt.
#
# Build:
#   docker build -f docker/Dockerfile.sandbox.r -t openra-sandbox-r:latest docker/
# (or: make build-r-sandbox)
#
# The container is always started with --network none so generated
# code cannot make outbound connections.  The dataset is mounted
# read-only at its host path and the generated script is mounted at
# /workspace/script.R.

FROM rocker/r2u:jammy

# ── R packages ──────────────────────────────────────────────────────────────
# install2.r is the docopt-based Rocker wrapper that understands the
# ``--error`` flag (surfacing install failures as non-zero exit codes,
# good for builds).  The simpler ``install.r`` littler script that ships
# in current r2u:jammy has no flag parsing, so it would treat ``--error``
# as a package name and fail.  r2u resolves the named packages as Debian
# binary packages so installation is fast and deterministic.
RUN install2.r --error \
    jsonlite \
    fixest \
    AER \
    plm \
    lmtest \
    sandwich \
    modelsummary \
    data.table \
    readr \
    dplyr \
    haven

# ── sandbox user (non-root) ────────────────────────────────────────────────
RUN groupadd -r sandbox && useradd -r -g sandbox -d /workspace -s /bin/false sandbox
RUN mkdir -p /workspace && chown sandbox:sandbox /workspace

WORKDIR /workspace
USER sandbox

# Generated script is always mounted at this path by RDockerExecutor.
CMD ["Rscript", "/workspace/script.R"]
