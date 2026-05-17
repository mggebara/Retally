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
 ClaimExtractor       Claude identifies quantitative claims,
 (Claude API)         dataset references, methodology summary, AND
                      paper-stated hyperparameters (canonical sklearn
                      kwarg names: C, n_estimators, random_state, …)
        │
        ▼
 DatasetRegistry      look up download details for the dataset
 DatasetDownloader    fetch from UCI / Kaggle / Zenodo / OpenML / URL
        │
        ▼
 CodeDownloader       shallow-clone any GitHub repo the paper linked,
 + selector           cherry-pick the most relevant Python files
                      (skipped when no code reference is found)
        │
        ▼
 CodeGenerator        Claude writes scikit-learn reproduction code
 (Claude API)         guided by methodology + claims + dataset schema,
                      seeded with reference code files when available
        │
        ▼
 CodeExecutor         run in subprocess  ──or──  DockerExecutor
 (subprocess)                                    (--network none,
                                                  --read-only, etc.)
        │
        ▼
 Refinement loop      Phase 1 — on Python error or empty output, ask
 (up to N retries)              CodeGenerator.refine and re-execute.
                      Phase 2 — if the code ran but any claim is outside
                                tolerance, ask CodeGenerator.refine_for_claims
                                to close the gap; the generator may emit
                                DEVIATION: notes if it has to change anything
                                the paper did not specify.
        │
        ▼
 ResultComparator     match reproduced metrics to paper claims,
                      apply per-metric tolerances (1 % default)
        │
        ▼
 HyperparameterAudit  AST-walk the FINAL generated code and check every
 (deterministic)      paper-stated hyperparameter against the literal
                      kwargs in the script.  Independent of claim
                      validation: 'all claims passed' does NOT imply
                      'reproduction used the paper's hyperparameters'.
        │
        ▼
 ValidationReport     Markdown / JSON / console output
                      (includes DEVIATION notes from Phase 2 and the
                       full hyperparameter audit table)
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
package.  Dev tooling lives in a PEP 735 dependency group, so pip ≥25.1
installs it via:

```bash
pip install -e .
pip install --group dev
```

(Older pips can still ``pip install -e .`` for the runtime deps; they
just need to install pytest / ruff / mypy / types-requests manually.)

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

report = pipeline.validate("path/to/paper.pdf", dataset_reference=ref)
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

### `ValidationPipeline.__init__` refinement parameters

These control the two refinement phases described in the
[how-it-works diagram](#how-it-works).  They are not surfaced through
`.default()` — pass them when constructing the pipeline directly.

| Parameter | Default | Description |
|---|---|---|
| `max_refinements` | `3` | Phase 1: number of `CodeGenerator.refine()` calls after the initial `generate()` when the code errors out or produces no `RESULT:` lines. Total executions in Phase 1 ≤ `max_refinements + 1`. |
| `max_claim_refinements` | `3` | Phase 2: number of `CodeGenerator.refine_for_claims()` calls after the code runs cleanly but at least one claim is outside tolerance. Stops early on no-progress, identical-code, or broken-refinement signals. Set to `0` to disable Phase 2. |
| `include_code_references` | `True` | When True, the pipeline runs an extra LLM pass to find repository URLs in the paper, shallow-clones GitHub ones, and seeds the generator with a selection of source files. Set to `False` to skip the extra LLM call and the clone (e.g. for offline runs or papers known to ship no code). |

When Phase 2 has to deviate from the paper's stated methodology to
close a gap (e.g. swap an unspecified hyperparameter), it emits a
`DEVIATION:<text>` stdout line.  These are parsed into
`ExecutionResult.deviation_notes` and surfaced in the markdown report's
`## Refinement` section, in `to_console()` output, and on the
dashboard.

### Hyperparameter audit

The pipeline checks whether the generated code actually used the
hyperparameters the paper specifies.  `ClaimExtractor.extract_hyperparameters`
pulls every paper-stated hyperparameter into a structured
`HyperparameterSpec` (using the canonical scikit-learn keyword
argument name — `C`, `n_estimators`, `random_state`, `test_size`,
`hidden_layer_sizes`, `cv`, …), and after Phase 1 + Phase 2 settle,
`validation.hyperparam_audit.audit_hyperparameters` walks the AST of
the final generated script and assigns each spec one of four
statuses:

| Status | Meaning |
|---|---|
| `match` | Code used the paper's value (numeric comparison uses a small float tolerance; tuple/list containers are interchangeable). |
| `mismatch` | Code used a different literal value for this kwarg. |
| `not_found` | The kwarg never appears in any call.  The code may still be using the library default at runtime, but we cannot prove conformance from the AST. |
| `unresolved` | The kwarg is present but bound to a variable / expression we cannot evaluate without executing the code. |

Results land on `ExecutionResult.hyperparameter_audits` and render in
all three output formats:

- **Markdown:** a `## Hyperparameter audit` section with a table of
  every spec / observed / status / note.
- **Console:** one summary line (`Hyperparameter audit: 3/4 matched`)
  plus a bullet per non-match.
- **Dashboard:** a table inside the report modal's Summary tab.

Caveat: this audit is **independent of claim validation**.  A paper
can have every claim pass while still failing the audit — the model
deviated from the stated hyperparameters and happened to hit the
number anyway — and vice versa.  These are different reproducibility
questions, intentionally tracked separately.  `overall_passed`
reflects only claim validation; the audit is informational.

### Reference-code baseline

Many ML papers ship the implementation that produced their numbers,
usually as a GitHub repository linked from the abstract or a "Code"
section.  When `include_code_references=True` (the default), OpenRA:

1. **Extracts URLs.**  `ClaimExtractor.extract_code_references` runs an
   LLM pass that finds repo links in the paper text and classifies
   each as `github` / `gitlab` / `bitbucket` / `zenodo` / `direct_url`
   / `unknown`.  Non-code URLs (PDFs, dataset pages, personal homepages)
   are filtered out.
2. **Clones.**  `CodeDownloader` shallow-clones GitHub repos
   (`--depth 1 --filter=blob:none`) into `.cache/code_repos/`.  A
   `.openra-clone-complete` sentinel marks finished clones for
   subsequent cache hits.  Other sources are recognised but not
   fetched yet — they surface in the report as "found but not
   fetched" so a reviewer knows the link exists.
3. **Selects relevant files.**  `select_relevant_files` picks up to
   20 files / 200 KB of source from each cloned repo, preferring
   top-level Python scripts with names like `train.py`, `main.py`,
   `model.py`, `run.py`, `reproduce.py`, `experiment.py`.  Skips
   `__init__.py`, tests, vendored deps, notebooks, examples, and
   anything larger than 20 KB per file.
4. **Seeds the generator.**  The selected files appear in a
   `## Reference Implementation` section of the generation prompt,
   with the instruction to adapt the real code rather than
   reconstruct from the methodology summary.  The model is told to
   swap dataset paths to `dataset.local_path/data.csv` and to omit
   experiments unrelated to the specific claims being reproduced.

Refinement prompts (Phase 1 and Phase 2) deliberately do NOT
re-paste the reference repo — they already have the previous code
and the specific error/gap to focus on, and re-sending would burn
tokens for no behavioural gain.  The reference is baked into the
original generation only.

Best-effort throughout: paper doesn't link code → no extraction
call.  Extractor finds no URLs → no clone attempts.  Repo is on a
non-GitHub host → reference is recorded but skipped.  Git is missing
on the host → clone is skipped with a clear log line.  Clone fails →
that reference contributes nothing.  In every case the pipeline
continues normally; you get a report without a reference baseline
rather than a crash.

References (cloned or not) appear in the markdown report as a
**Reference code** bullet list under the dataset, in console output
as a `Reference code: N/M cloned` summary line, and on the dashboard
modal as a list with per-link status.

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
