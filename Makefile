.PHONY: build-sandbox rebuild-sandbox test lint format typecheck check sync lock clean

SANDBOX_IMAGE := openra-sandbox:latest
DOCKERFILE    := docker/Dockerfile.sandbox

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
	uv run ruff check src/ tests/

## Auto-format with ruff.
format:
	uv run ruff format src/ tests/

## Type-check with mypy.
typecheck:
	uv run mypy src/openra

## Run every CI check locally in one go.
check: lint typecheck test
	uv run ruff format --check src/ tests/

## Remove the local venv and caches.
clean:
	rm -rf .venv .pytest_cache .ruff_cache .mypy_cache build dist src/*.egg-info

## Build the offline sandbox Docker image (required before using DockerExecutor).
build-sandbox:
	docker build -f $(DOCKERFILE) -t $(SANDBOX_IMAGE) docker/

## Force a full rebuild with no layer cache (e.g. after changing requirements).
rebuild-sandbox:
	docker build --no-cache -f $(DOCKERFILE) -t $(SANDBOX_IMAGE) docker/
