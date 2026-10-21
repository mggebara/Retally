# Retally

*Implemented with [Claude Code](https://claude.com/claude-code).*

Retally re-tallies the numbers in academic papers: it reads a paper, downloads the relevant dataset, generates reproduction code via the Claude API (scikit-learn for ML papers, R + fixest/AER/plm for econometrics), executes it in an isolated environment, and compares the reproduced numbers against the paper's stated results.

- **The real evaluation:** [`benchmark/README.md`](benchmark/README.md) — a harness that scores the pipeline (or any agent implementing its `Reproducer` protocol) against the [Institute for Replication](https://i4replication.org) catalog of hand-replicated papers.
- **Demo dashboard:** [`docs/index.html`](docs/index.html) — demo runs of the pipeline on synthetic paper text. These are smoke tests of the tooling, *not* real reproducibility verdicts.
- **Plan:** [`ROADMAP.md`](ROADMAP.md). **Full reference:** [`docs/reference.md`](docs/reference.md).

## How it works

1. **Parse** the paper (PDF, arXiv ID, DOI, URL, or raw text) — `PaperParser`.
2. **Extract** quantitative claims, dataset references, methodology, paper-stated hyperparameters, and code links with Claude — `ClaimExtractor`.
3. **Fetch** the dataset (built-in registry; UCI / Kaggle / Zenodo / OpenML / URL) and shallow-clone any linked GitHub repo — `DatasetDownloader`, `CodeDownloader`.
4. **Generate** reproduction code in the paper's language (Python/sklearn or R/fixest+AER+plm), seeded with the linked repo's code and the replication package's own `.R`/`.do`/`.Rmd` scripts when present (the default `seeded` mode — a computational reproduction), or from the paper text alone with those withheld (`independent` mode); see [reproduction modes](docs/reference.md#reproduction-modes-seeded-vs-independent) — `CodeGenerator`.
5. **Execute** in a network-less Docker sandbox — `DockerExecutor` / `RDockerExecutor`.
6. **Refine** (bounded retries): fix errors or empty output, then try to close gaps on claims outside tolerance, recording any `DEVIATION:` from the paper's method.
7. **Compare** reproduced values against the claims with per-metric tolerances (widened to ±1·SE in independent mode when a standard error is pinned) — `ResultComparator`.
8. **Audit** the final code's literal hyperparameters against the paper's, and **report** as Markdown / JSON / console — `ValidationReporter`.

The hyperparameter audit is independent of claim validation: "all claims passed" does not imply the paper's hyperparameters were used, and `overall_passed` reflects claims only. Each stage is a standalone class that can be swapped or called on its own; see the [architecture tree](docs/reference.md#architecture).

## Requirements

- Python ≥ 3.11 and [uv](https://docs.astral.sh/uv/)
- An [Anthropic API key](https://console.anthropic.com/)
- Docker ≥ 20 for the default sandboxed execution

## Installation

```bash
git clone https://github.com/mggebara/retally.git
cd retally
uv sync          # creates .venv from uv.lock, installs the project + dev group
```

Prefix commands with `uv run`; no manual venv activation is needed. Heavy ML
libraries live in the Docker image, not on the host. Optional extras, composed
with `uv sync --extra <name>`:

- `host-exec` — scikit-learn/numpy/scipy, to run generated code without Docker
- `uci`, `kaggle`, `openml` — dataset backends for those sources

A pip-only install also works; see [docs/reference.md](docs/reference.md#pip-only-install).

### API key

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

## Quick start

```python
from retally import ValidationPipeline
from retally.validation.reporter import ValidationReporter

pipeline = ValidationPipeline.default()
report = pipeline.validate("your-paper-source-here")

reporter = ValidationReporter()
print(reporter.to_console(report))   # coloured terminal summary
reporter.save(report, "report.md")   # full Markdown report (or .json)
```

`validate()` accepts any of:

```python
pipeline.validate("path/to/paper.pdf")                  # local PDF
pipeline.validate("1601.02611")                          # arXiv ID
pipeline.validate("10.1145/1015330.1015339")             # DOI
pipeline.validate("https://arxiv.org/pdf/1601.02611")    # URL (PDF or HTML)
pipeline.validate("Title\n\nAbstract\n...")              # raw text
```

To pin the dataset instead of relying on auto-detection, pass `dataset_reference=`;
see [Supported datasets](docs/reference.md#supported-datasets). Report fields are
described under [Output](docs/reference.md#output).

## Docker sandbox

Generated code runs in Docker by default. Build the images once:

```bash
make build-sandbox     # retally-sandbox:latest   (Python: sklearn, xgboost, statsmodels, …)
make build-r-sandbox   # retally-sandbox-r:latest (R: fixest, AER, plm, sandwich, …)
```

The R image is only needed when an R paper arrives. Both executors apply the
same isolation: `--network none`, `--read-only` (plus a RAM-only `/tmp`),
`--cap-drop ALL`, `--security-opt no-new-privileges`, and `--memory`/`--cpus`
caps. The dataset is downloaded on the host first and mounted read-only.

`ValidationPipeline.default()` **raises** if Docker or the image is unavailable
rather than silently running Claude-generated code on the host. Where you
already have other isolation (a throwaway VM, CI), `allow_unsafe_subprocess=True`
falls back to a plain subprocess with a warning (Python papers only). Resource
limits and other options: [Configuration](docs/reference.md#configuration).

## Benchmark harness

The harness runs Retally against the I4R catalog and records three independent
verdicts per paper — `retally_ran`, `agrees_with_paper`, `agrees_with_i4r` —
with typed skips for entries it cannot run. The harness, not the pipeline,
computes the verdicts: the pipeline is plugged in as one *reproducer* that
returns raw values, so another agent can sit the same exam by implementing the
`Reproducer` protocol in `benchmark/reproducer.py`.

```bash
make benchmark           # run the catalog, write benchmark/results/REPORT.md
make benchmark-report    # re-render from cached results.json
uv run python -m benchmark.runner --mode both                   # seeded + independent
uv run python -m benchmark.runner --mode all                    # + blind (targets withheld)
uv run python -m benchmark.runner --reproducer my_pkg.mod:make  # score another agent
```

Catalog schema, claim-pinning rubric, LLM-call cache (`RETALLY_LLM_CACHE=0` for a
fully live run), the prompt-tuning workflow, and how to plug in another agent:
[`benchmark/README.md`](benchmark/README.md).

## Development

```bash
make sync          # uv sync
make test          # uv run pytest tests/ -v
make lint          # ruff check (src, tests, scripts, benchmark)
make format        # ruff format
make typecheck     # mypy src/retally
make check         # lint + typecheck + tests + format check (mirrors CI)
make lock          # re-resolve uv.lock after changing dependencies
make clean         # remove .venv and tool caches
make rebuild-sandbox / make rebuild-r-sandbox   # rebuild images with no layer cache
```

Tests that need network access, a Docker daemon, or an API key skip
automatically when those are unavailable. `uv.lock` is committed and CI runs
`uv sync --frozen`, so run `make lock` after changing dependencies.
