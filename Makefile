.PHONY: build-sandbox rebuild-sandbox build-r-sandbox rebuild-r-sandbox check-r-sandbox test lint format typecheck check sync lock clean benchmark benchmark-report

SANDBOX_IMAGE := retally-sandbox:latest
DOCKERFILE    := docker/Dockerfile.sandbox

R_SANDBOX_IMAGE := retally-sandbox-r:latest
R_DOCKERFILE    := docker/Dockerfile.sandbox.r

## Sync the project venv from uv.lock (creates .venv if missing, installs
## the project + dev dependency group).  Run this once after cloning.
sync:
	uv sync

## Re-resolve dependencies and update uv.lock.
lock:
	uv lock

## Run the test suite inside the project's uv-managed venv.
test:
	uv run pytest tests/ -v

## Lint with ruff.
lint:
	uv run ruff check src/ tests/ scripts/ benchmark/

## Auto-format with ruff.
format:
	uv run ruff format src/ tests/ scripts/ benchmark/

## Type-check with mypy.
typecheck:
	uv run mypy src/retally

## Run every CI check locally in one go.
check: lint typecheck test
	uv run ruff format --check src/ tests/ scripts/ benchmark/

## Remove the local venv and caches.
clean:
	rm -rf .venv .pytest_cache .ruff_cache .mypy_cache build dist src/*.egg-info

## Run the I4R benchmark suite end-to-end.
## Requires ANTHROPIC_API_KEY for any benchmark/papers/*.yaml with
## language: python.  Other entries skip with a recorded reason.
## Writes results.json + REPORT.md + report.html under benchmark/results/.
benchmark:
	uv run python -m benchmark.runner
	$(MAKE) benchmark-report

## Re-render the benchmark report from the existing results.json.
## Useful when you've tweaked the renderer and don't want to re-run
## the (expensive) pipeline against the catalog.
benchmark-report:
	uv run python -m benchmark.report

## Build the offline sandbox Docker image (required before using DockerExecutor).
build-sandbox:
	docker build -f $(DOCKERFILE) -t $(SANDBOX_IMAGE) docker/

## Force a full rebuild with no layer cache (e.g. after changing requirements).
rebuild-sandbox:
	docker build --no-cache -f $(DOCKERFILE) -t $(SANDBOX_IMAGE) docker/

## Build the R-flavoured sandbox image (required before using RDockerExecutor),
## then load-test every package it promises.
build-r-sandbox:
	docker build -f $(R_DOCKERFILE) -t $(R_SANDBOX_IMAGE) docker/
	$(MAKE) check-r-sandbox

## Force a full rebuild of the R sandbox image.
rebuild-r-sandbox:
	docker build --no-cache -f $(R_DOCKERFILE) -t $(R_SANDBOX_IMAGE) docker/
	$(MAKE) check-r-sandbox

## Load every package in docker/requirements.sandbox.r.txt (plus base/recommended
## packages) inside the R sandbox image, offline and as the sandbox user.
## Fails if any package is missing.
check-r-sandbox:
	docker run --rm --network none -v "$(CURDIR)/docker:/check:ro" $(R_SANDBOX_IMAGE) \
		Rscript /check/check-r-packages.R /check/requirements.sandbox.r.txt
