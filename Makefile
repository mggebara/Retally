.PHONY: build-sandbox rebuild-sandbox test lint format typecheck check sync lock clean leaderboard check-leaderboard-fresh

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
	uv run ruff check src/ tests/ scripts/

## Auto-format with ruff.
format:
	uv run ruff format src/ tests/ scripts/

## Type-check with mypy.
typecheck:
	uv run mypy src/openra

## Run every CI check locally in one go.
check: lint typecheck test
	uv run ruff format --check src/ tests/ scripts/
	$(MAKE) check-leaderboard-fresh

## Fail if LEADERBOARD.md or docs/data/leaderboard.json is out of sync with
## docs/data/reports.json — catches contributors who add a report but forget
## to run ``make leaderboard``.
check-leaderboard-fresh:
	uv run python scripts/generate_leaderboard.py >/dev/null
	@git diff --exit-code -- LEADERBOARD.md docs/data/leaderboard.json \
	  || (echo "ERROR: leaderboard artefacts are stale. Run 'make leaderboard' and commit." && exit 1)

## Remove the local venv and caches.
clean:
	rm -rf .venv .pytest_cache .ruff_cache .mypy_cache build dist src/*.egg-info

## Regenerate LEADERBOARD.md and docs/data/leaderboard.json from reports.json.
leaderboard:
	uv run python scripts/generate_leaderboard.py

## Build the offline sandbox Docker image (required before using DockerExecutor).
build-sandbox:
	docker build -f $(DOCKERFILE) -t $(SANDBOX_IMAGE) docker/

## Force a full rebuild with no layer cache (e.g. after changing requirements).
rebuild-sandbox:
	docker build --no-cache -f $(DOCKERFILE) -t $(SANDBOX_IMAGE) docker/
