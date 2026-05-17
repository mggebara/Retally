# OpenRA — Open Source Research Assistant

OpenRA automates the validation of academic papers: it reads a paper, downloads the relevant dataset, generates scikit-learn reproduction code via the Claude API, executes it in an isolated environment, and compares the reproduced numbers against the paper's stated results.

See [`LEADERBOARD.md`](LEADERBOARD.md) for an at-a-glance view of which authors' papers have been reproducibly validated so far, plus a [browsable dashboard of every report](docs/index.html).

---

## Table of contents

1. [How it works](#how-it-works)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Quick start — one command](#quick-start--one-command)
5. [Worked example: Breast Cancer Wisconsin paper](#worked-example-breast-cancer-wisconsin-paper)
6. [Running with a PDF or arXiv paper](#running-with-a-pdf-or-arxiv-paper)
7. [Docker sandbox (recommended)](#docker-sandbox-recommended)
8. [Understanding the output](#understanding-the-output)
9. [Supported datasets](#supported-datasets)
10. [Architecture](#architecture)
11. [Configuration reference](#configuration-reference)
12. [Development](#development)

---

## How it works

```
Paper (PDF / arXiv ID / URL / text)
        │
        ▼
 PaperParser          extract raw text, title, abstract
        │
        ▼
 ClaimExtractor       Claude identifies quantitative claims
 (Claude API)         and dataset references
        │
        ▼
 DatasetRegistry      look up download details for the dataset
 DatasetDownloader    fetch from UCI / Kaggle / Zenodo / OpenML / URL
        │
        ▼
 CodeGenerator        Claude writes scikit-learn reproduction code
 (Claude API)         guided by methodology + claims + dataset schema
        │
        ▼
 CodeExecutor         run in subprocess  ──or──  DockerExecutor
 (subprocess)                                    (--network none,
                                                  --read-only, etc.)
        │
        ▼
 ResultComparator     match reproduced metrics to paper claims,
                      apply per-metric tolerances (1 % default)
        │
        ▼
 ValidationReport     Markdown / JSON / console output
```

Each step is a standalone class that can be swapped out or called independently.

---

## Requirements

| Requirement | Notes |
|---|---|
| Python ≥ 3.11 | |
| [Anthropic API key](https://console.anthropic.com/) | Set as `ANTHROPIC_API_KEY` env var |
| Docker ≥ 20 | Only needed for the Docker sandbox mode |

---

## Installation

OpenRA uses [uv](https://docs.astral.sh/uv/) for environment and
dependency management.  Install it once
([install instructions](https://docs.astral.sh/uv/getting-started/installation/)),
then:

```bash
git clone https://github.com/mggebara/openra.git
cd openra
uv sync
```

`uv sync` creates `.venv/` from `uv.lock`, installs the project in
editable mode, and pulls the `dev` dependency group (pytest, ruff,
mypy, plus every dataset backend used by the test suite).  No manual
venv activation is needed — prefix commands with `uv run` and the
project venv is used automatically:

```bash
uv run pytest        # tests
uv run ruff check .  # lint
make check           # runs the full CI suite locally
```

### Optional extras

The base install pulls only what the host actually needs: the Claude
API client, PyMuPDF for paper parsing, and pandas/requests for the
dataset downloader.  Heavy ML libraries (scikit-learn, numpy, scipy)
live in the Docker sandbox image and are NOT installed on the host by
default.

| Extra | Adds | When to use it |
|---|---|---|
| `host-exec` | scikit-learn, numpy, scipy | You want to run generated code via the subprocess executor instead of Docker. |
| `kaggle` | kaggle | You will download datasets from Kaggle. |
| `uci` | ucimlrepo | You will download datasets from the UCI ML Repository. |
| `openml` | openml | You will download datasets from OpenML. |

Compose extras at sync time:

```bash
uv sync --extra uci --extra kaggle
```

### Pip-only install

If you do not want to use uv, the project is still a standard PEP 621
package:

```bash
pip install -e ".[dev]"
```

### API key

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

---

## Quick start — one command

```python
from openra import ValidationPipeline

pipeline = ValidationPipeline.default()

# Pass an arXiv ID, a local PDF path, a DOI, a URL, or raw paper text.
report = pipeline.validate("your-paper-source-here")

# Print a coloured summary to the terminal
from openra.validation.reporter import ValidationReporter
reporter = ValidationReporter()
print(reporter.to_console(report))

# Save a full Markdown report
reporter.save(report, "report.md")
```

---

## Worked example: Breast Cancer Wisconsin paper

The example below reproduces the classic logistic-regression benchmark on the
[Breast Cancer Wisconsin (Diagnostic)](https://archive.ics.uci.edu/dataset/17/breast+cancer+wisconsin+diagnostic)
dataset, one of the most-cited UCI benchmarks.  The dataset is pre-registered
in the built-in registry, so no manual download step is required.

### 1. Create the example script

```bash
cat > validate_example.py << 'EOF'
"""
Reproduce a simple Breast Cancer Wisconsin benchmark.

We feed the pipeline the paper text directly as a string so this example
works without a real PDF.  In production you would pass a PDF path or
arXiv ID instead.
"""

import os
from openra import ValidationPipeline
from openra.validation.reporter import ValidationReporter

# Minimal paper description — in a real run this comes from a PDF or arXiv.
PAPER_TEXT = """
Logistic Regression on the Breast Cancer Wisconsin Dataset

Authors: Example Author

Abstract:
We apply logistic regression to the Breast Cancer Wisconsin (Diagnostic) dataset
and report classification accuracy on a held-out test set.

Methods:
We use the Breast Cancer Wisconsin (Diagnostic) dataset from the UCI Machine
Learning Repository (569 instances, 30 numeric features, binary target:
malignant/benign). Features are standardised with zero mean and unit variance.
We train a logistic regression classifier (L2 penalty, C=1.0, random_state=42)
using an 80/20 stratified train/test split. Performance is evaluated on the
held-out test set.

Results:
Table 1 reports classification results on the test set.
Our logistic regression achieves a test accuracy of 97.4% and an F1 score of 0.973.
"""

def main():
    pipeline = ValidationPipeline.default(
        anthropic_api_key=os.environ.get("ANTHROPIC_API_KEY"),
    )

    print("Running validation pipeline…")
    report = pipeline.validate(PAPER_TEXT)

    reporter = ValidationReporter()

    # Console summary
    print()
    print(reporter.to_console(report))

    # Save full reports
    reporter.save(report, "report.md")
    reporter.save(report, "report.json")
    print()
    print("Full reports saved to report.md and report.json")

if __name__ == "__main__":
    main()
EOF
```

### 2. Run it

```bash
python validate_example.py
```

Expected console output (numbers will vary slightly by run):

```
Validation Report: Logistic Regression on the Breast Cancer Wisconsin Dataset
Overall: PASSED
Summary: 2 of 2 claims validated.

  [PASSED] test accuracy: paper=97.4, reproduced=97.37
  [PASSED] F1 score: paper=0.973, reproduced=0.9732
```

### 3. Read the full report

```bash
cat report.md
```

The Markdown report includes the claims table, the generated Python code, and
the full stdout/stderr from execution.

---

## Running with a PDF or arXiv paper

The pipeline accepts multiple input formats.  Pass whichever is most convenient:

```python
from openra import ValidationPipeline

pipeline = ValidationPipeline.default()

# Local PDF file
report = pipeline.validate("path/to/paper.pdf")

# arXiv ID  (fetches metadata + PDF automatically)
report = pipeline.validate("1601.02611")   # Random Forests revisited

# DOI
report = pipeline.validate("10.1145/1015330.1015339")

# Direct URL to a PDF or HTML page
report = pipeline.validate("https://arxiv.org/pdf/1601.02611")

# Raw paper text (useful for testing)
report = pipeline.validate("Title\n\nAbstract\n...")
```

### Bypassing dataset auto-detection

If the extractor cannot find the dataset, or you want to pin a specific
version, pass it explicitly:

```python
from openra import ValidationPipeline
from openra.models import DatasetReference, DatasetSource

pipeline = ValidationPipeline.default()

ref = DatasetReference(
    name="Breast Cancer Wisconsin",
    source=DatasetSource.UCI,
    url="17",           # UCI dataset ID
)

report = pipeline.validate_with_known_dataset("path/to/paper.pdf", ref)
```

---

## Docker sandbox (default)

The Docker executor runs generated code with **zero network access** and a
read-only filesystem, providing OS-level isolation independent of the AST
preflight check.  This is the default execution mode: a call to
`ValidationPipeline.default()` will raise if Docker is unavailable, rather
than silently degrading to running Claude-generated code on the host.

### Build the sandbox image (one-time)

```bash
make build-sandbox
# or equivalently:
# docker build -f docker/Dockerfile.sandbox -t openra-sandbox:latest docker/
```

The image contains: `scikit-learn`, `xgboost`, `lightgbm`, `pandas`, `numpy`,
`scipy`, `statsmodels`, `matplotlib`.  It is built offline-capable — no
internet access is needed once the image is built.

### Tune resource limits

```python
from openra import ValidationPipeline

pipeline = ValidationPipeline.default(
    docker_memory="4g",       # RAM cap per run (default 4g)
    docker_cpus=1.0,          # CPU cap per run (default 1.0)
)

report = pipeline.validate("path/to/paper.pdf")
```

If Docker is unavailable or the image is not built, `default()` raises a
`RuntimeError` explaining how to build the sandbox.  In throwaway / CI
environments where you have other isolation already, you can pass
`allow_unsafe_subprocess=True` to fall back to the subprocess executor
with a warning.

### Isolation guarantees

| Flag applied | Effect |
|---|---|
| `--network none` | No outbound connections during code execution |
| `--read-only` | Immutable container filesystem |
| `--tmpfs /tmp:size=256m` | Writable scratch space in RAM only |
| `--cap-drop ALL` | All Linux capabilities removed |
| `--security-opt no-new-privileges` | No privilege escalation |
| `--memory` / `--cpus` | Resource caps prevent runaway processes |

The dataset is downloaded to the host by `DatasetDownloader` *before*
execution, then mounted read-only at its exact host path inside the container.

---

## Understanding the output

### ValidationReport fields

| Field | Type | Description |
|---|---|---|
| `paper` | `Paper` | Parsed paper (title, authors, claims, …) |
| `dataset` | `Dataset` | Downloaded dataset metadata |
| `execution_result` | `ExecutionResult` | Generated code, stdout, stderr, exit code |
| `claim_results` | `list[ClaimValidationResult]` | Per-claim comparison |
| `overall_passed` | `bool` | True only when every claim passes |
| `summary` | `str` | One-line human summary |

### ClaimValidationResult

| Field | Description |
|---|---|
| `claim.value` | Number stated in the paper |
| `reproduced_value` | Number produced by the generated code |
| `tolerance` | Allowed relative error (default 1 %) |
| `passed` | True if `|reproduced - claimed| / claimed ≤ tolerance` |
| `notes` | Explanation of failures or unit-mismatch adjustments |

The comparator automatically handles **percentage vs. decimal mismatches**:
if a paper states "97.4%" and the code produces `0.974`, the claim still passes
with a note in the `notes` field.

### Saving reports

```python
from openra.validation.reporter import ValidationReporter

reporter = ValidationReporter()

reporter.save(report, "report.md")       # Markdown
reporter.save(report, "report.json")     # JSON
print(reporter.to_console(report))       # ANSI-coloured terminal output
print(reporter.to_markdown(report))      # Markdown string
```

---

## Supported datasets

The built-in registry pre-populates 28 classic datasets so no manual URL is
needed for papers that use them.

### UCI ML Repository (auto-downloaded via `ucimlrepo`)

| Dataset | Registry key |
|---|---|
| Iris | `iris` |
| Adult Income | `adult income` |
| Breast Cancer Wisconsin | `breast cancer wisconsin` |
| Wine | `wine` |
| Heart Disease | `heart disease` |
| Ionosphere | `ionosphere` |
| Sonar | `sonar` |
| Pima Indians Diabetes | `pima indians diabetes` |
| German Credit | `german credit` |
| Letter Recognition | `letter recognition` |
| Mushroom | `mushroom` |
| Spambase | `spambase` |
| Abalone | `abalone` |
| Ecoli | `ecoli` |
| Yeast | `yeast` |
| Glass Identification | `glass identification` |
| Balance Scale | `balance scale` |
| Tic-Tac-Toe Endgame | `tic-tac-toe endgame` |
| Waveform | `waveform` |
| Zoo | `zoo` |
| Car Evaluation | `car evaluation` |
| Congressional Voting Records | `congressional voting records` |
| Soybean Large | `soybean large` |
| Statlog Shuttle | `statlog shuttle` |

### Other sources

| Dataset | Source | Registry key |
|---|---|---|
| MNIST | OpenML | `mnist` |
| Boston Housing | OpenML | `boston housing` |
| California Housing | OpenML | `california housing` |
| Titanic | Kaggle | `titanic` |

### Adding a custom dataset

```python
from openra.models import DatasetReference, DatasetSource
from openra.dataset.registry import DatasetRegistry

registry = DatasetRegistry()
registry.load()
registry.register(DatasetReference(
    name="My Dataset",
    source=DatasetSource.DIRECT_URL,
    url="https://example.com/data.zip",
    description="Binary classification benchmark",
))
```

---

## Architecture

```
src/openra/
├── models.py                  Shared dataclasses
├── pipeline.py                ValidationPipeline orchestrator
├── paper/
│   ├── parser.py              PaperParser   (PDF, arXiv, DOI, URL, text)
│   └── extractor.py           ClaimExtractor  (Claude-backed)
├── dataset/
│   ├── registry.py            DatasetRegistry (JSON-backed, 28 builtins)
│   └── downloader.py          DatasetDownloader (UCI/Kaggle/Zenodo/OpenML/URL)
├── codegen/
│   ├── generator.py           CodeGenerator  (Claude-backed, scikit-learn focus)
│   ├── executor.py            CodeExecutor   (subprocess sandbox)
│   └── docker_executor.py     DockerExecutor (OS-level isolation)
└── validation/
    ├── comparator.py          ResultComparator (tolerance + % handling)
    └── reporter.py            ValidationReporter (Markdown / JSON / console)

docker/
├── Dockerfile.sandbox         Offline ML sandbox image
└── requirements.sandbox.txt   Pinned ML packages for the image

tests/                         58 passing, 10 skipped (network/Docker)
Makefile                       build-sandbox / test / lint / install
```

---

## Configuration reference

### `ValidationPipeline.default()` parameters

| Parameter | Default | Description |
|---|---|---|
| `anthropic_api_key` | `None` (reads `ANTHROPIC_API_KEY`) | Anthropic API key |
| `use_docker` | `True` | Use `DockerExecutor` for OS-level isolation. Set to `False` to opt into the subprocess `CodeExecutor` with no isolation. |
| `allow_unsafe_subprocess` | `False` | When `use_docker=True` but Docker is unavailable, fall back to the subprocess executor instead of raising. |
| `docker_image` | `"openra-sandbox:latest"` | Docker image tag |
| `docker_memory` | `"4g"` | Container memory limit |
| `docker_cpus` | `1.0` | Container CPU limit |

### `CodeExecutor` parameters

| Parameter | Default | Description |
|---|---|---|
| `timeout` | `300` | Seconds before the subprocess is killed |
| `work_dir` | `None` (temp dir per run) | Working directory for the script |

### `DockerExecutor` parameters

| Parameter | Default | Description |
|---|---|---|
| `image` | `"openra-sandbox:latest"` | Docker image tag |
| `timeout` | `300` | Seconds before the container is killed |
| `memory_limit` | `"4g"` | Docker `--memory` value |
| `cpu_count` | `1.0` | Docker `--cpus` value |

### `ResultComparator` parameters

| Parameter | Default | Description |
|---|---|---|
| `default_tolerance` | `0.01` | Relative tolerance for `OTHER`-type claims |

Per-type tolerances (not overridable without subclassing):
`ACCURACY` / `F1` / `AUC` / `PRECISION` / `RECALL` → 1 %,
`RMSE` / `MAE` → 5 %, `CORRELATION` → 2 %, `P_VALUE` → 0.1 %.

---

## Development

```bash
make sync            # uv sync — create/refresh .venv from uv.lock
make test            # uv run pytest tests/ -v
make lint            # uv run ruff check src/ tests/
make format          # uv run ruff format src/ tests/
make typecheck       # uv run mypy src/openra
make check           # lint + typecheck + tests + format check (mirrors CI)
make lock            # uv lock — re-resolve and update uv.lock
make clean           # remove .venv and tool caches

make build-sandbox   # build the Docker sandbox image
make rebuild-sandbox # rebuild with no layer cache
```

Tests that require network access or a running Docker daemon are
automatically skipped when those resources are unavailable.

`uv.lock` is committed.  CI runs `uv sync --frozen` so any drift between
`uv.lock` and `pyproject.toml` fails the build — run `make lock` after
changing dependencies.
