.PHONY: build-sandbox rebuild-sandbox test lint typecheck install

SANDBOX_IMAGE := openra-sandbox:latest
DOCKERFILE    := docker/Dockerfile.sandbox

## Build the offline sandbox Docker image (required before using DockerExecutor).
build-sandbox:
	docker build -f $(DOCKERFILE) -t $(SANDBOX_IMAGE) docker/

## Force a full rebuild with no layer cache (e.g. after changing requirements).
rebuild-sandbox:
	docker build --no-cache -f $(DOCKERFILE) -t $(SANDBOX_IMAGE) docker/

## Run the test suite.
## Uses ``python -m pytest`` so a globally-installed pytest in its own venv
## (e.g. via uv) doesn't run against an environment that lacks ``openra``.
test:
	python -m pytest tests/ -v

## Lint with ruff.
lint:
	ruff check src/ tests/

## Type-check with mypy.
typecheck:
	python -m mypy src/openra

## Install the package and dev dependencies in editable mode.
install:
	pip install -e ".[dev]"
