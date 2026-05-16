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
test:
	pytest tests/ -v

## Lint with ruff.
lint:
	ruff check src/ tests/

## Type-check with mypy.
typecheck:
	mypy src/openra

## Install the package and dev dependencies in editable mode.
install:
	pip install -e ".[dev]"
