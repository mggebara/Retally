# retally-sandbox-r
#
# Offline execution environment for ML / econometrics reproduction
# code written in R.  Built on Rocker's r2u image, which provides
# fast binary package installation from CRAN via apt.
#
# Build:
#   docker build -f docker/Dockerfile.sandbox.r -t retally-sandbox-r:latest docker/
# (or: make build-r-sandbox)
#
# The container is always started with --network none so generated
# code cannot make outbound connections.  The dataset is mounted
# read-only at its host path and the generated script is mounted at
# /workspace/script.R.

FROM rocker/r2u:noble

# ── R packages ──────────────────────────────────────────────────────────────
# requirements.sandbox.r.txt is the single source of truth for the package
# list (comments stripped below).  install2.r is the docopt-based Rocker
# wrapper that understands ``--error`` (install failures become non-zero
# exit codes).  The simpler ``install.r`` littler script that ships in
# current r2u images has no flag parsing, so it would treat ``--error`` as
# a package name and fail.  r2u resolves every name to an Ubuntu binary
# (r-cran-<name>) via bspm, so nothing is compiled.  The apt lists are
# removed afterwards to keep the layer small.
COPY requirements.sandbox.r.txt check-r-packages.R /opt/retally/
RUN install2.r --error $(sed -e 's/#.*//' /opt/retally/requirements.sandbox.r.txt | xargs) \
    && rm -rf /var/lib/apt/lists/* /tmp/downloaded_packages

# ── disable bspm at runtime ────────────────────────────────────────────────
# r2u's Rprofile.site calls bspm::enable() at every R startup.  As the
# non-root sandbox user with no D-Bus, bspm prints a multi-line
# "D-Bus service not found!" warning on every Rscript run, and that stderr
# is fed back to the model during refinement.  The container runs with
# --network none, so runtime installs are impossible anyway: drop the
# enable call once all packages are installed.
RUN sed -i 's/^suppressMessages(bspm::enable())/# bspm disabled at runtime (retally sandbox has no network)/' \
        /etc/R/Rprofile.site \
    && ! grep -q 'bspm::enable' /etc/R/Rprofile.site

# ── sandbox user (non-root) ────────────────────────────────────────────────
RUN groupadd -r sandbox && useradd -r -g sandbox -d /workspace -s /bin/false sandbox
RUN mkdir -p /workspace && chown sandbox:sandbox /workspace

WORKDIR /workspace
USER sandbox

# Generated script is always mounted at this path by RDockerExecutor.
CMD ["Rscript", "/workspace/script.R"]
