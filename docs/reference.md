# Retally reference

Detailed reference material for Retally. The [README](../README.md) is the
front door (what it is, install, quick start); this page holds the details.
Benchmark-specific documentation lives in
[`benchmark/README.md`](../benchmark/README.md).

## Contents

1. [Configuration](#configuration)
   - [`ValidationPipeline.default()`](#validationpipelinedefault)
   - [`ValidationPipeline.validate()`](#validationpipelinevalidate)
   - [Refinement parameters](#refinement-parameters)
   - [Executors](#executors)
   - [`ResultComparator` tolerances](#resultcomparator-tolerances)
2. [Hyperparameter audit](#hyperparameter-audit)
3. [Reference-code baseline](#reference-code-baseline)
4. [Replication-package scripts](#replication-package-scripts)
5. [Docker sandbox details](#docker-sandbox-details)
6. [Output](#output)
7. [Supported datasets](#supported-datasets)
8. [Pip-only install](#pip-only-install)
9. [Architecture](#architecture)

---

## Configuration

### `ValidationPipeline.default()`

| Parameter | Default | Description |
|---|---|---|
| `anthropic_api_key` | `None` (reads `ANTHROPIC_API_KEY`) | Anthropic API key. |
| `use_docker` | `True` | Run generated code in `DockerExecutor` for OS-level isolation. `False` opts into the subprocess `CodeExecutor` with no isolation. |
| `allow_unsafe_subprocess` | `False` | When `use_docker=True` but Docker is unavailable, fall back to the subprocess executor (with a warning) instead of raising `RuntimeError`. Does not apply to R papers — there is no host R fallback. |
| `docker_image` | `"retally-sandbox:latest"` | Image for the Python `DockerExecutor`. |
| `docker_r_image` | `"retally-sandbox-r:latest"` | Image for `RDockerExecutor`. Only checked when an R paper actually runs. |
| `docker_memory` | `"4g"` | Container memory limit. |
| `docker_cpus` | `1.0` | Container CPU limit. |
| `llm_cache_dir` | `None` | When set, every Claude call is cached on disk under this directory, keyed by the full request content, so unchanged calls replay for free. `None` means fully live. (The benchmark runner enables this by default; `RETALLY_LLM_CACHE=0` turns it off there.) |

```python
pipeline = ValidationPipeline.default(docker_memory="8g", docker_cpus=2.0)
```

### `ValidationPipeline.validate()`

`validate(paper_source, *, dataset_reference=None, language=None, claims=None)`

- `paper_source` — local PDF/`.txt` path, arXiv ID, DOI, URL, or raw text.
- `dataset_reference` — pin the dataset and skip dataset auto-detection
  (see [Supported datasets](#supported-datasets) for an example).
- `language` — force Python or R code generation instead of using the
  extracted language.
- `claims` — pre-pinned claims; skips the claims-extraction call (this is
  what the benchmark's pinned-claims workflow uses).

### Refinement parameters

These control the two refinement phases. They are not surfaced through
`.default()` — pass them when constructing `ValidationPipeline(...)` directly.

| Parameter | Default | Description |
|---|---|---|
| `max_refinements` | `3` | Phase 1: number of `CodeGenerator.refine()` calls after the initial `generate()` when the code errors out or produces no `RESULT:` lines. Total Phase 1 executions ≤ `max_refinements + 1`. |
| `max_claim_refinements` | `3` | Phase 2: number of `CodeGenerator.refine_for_claims()` calls after the code runs cleanly but at least one claim is outside tolerance. Stops early on no-progress, identical-code, or broken-refinement signals. `0` disables Phase 2. |
| `include_code_references` | `True` | Run an extra LLM pass to find repository URLs in the paper, shallow-clone GitHub ones, and seed the generator with selected source files. `False` skips the extra call and the clone (offline runs, papers known to ship no code). |

When Phase 2 has to deviate from the paper's stated methodology to close a
gap (e.g. swap an unspecified hyperparameter), the generated code emits a
`DEVIATION:<text>` stdout line. These are parsed into
`ExecutionResult.deviation_notes` and surfaced in the Markdown report's
`## Refinement` section and in `to_console()` output.

### Executors

`CodeExecutor` (subprocess, Python only, AST preflight guard only — not a
security boundary):

| Parameter | Default | Description |
|---|---|---|
| `timeout` | `300` | Seconds before the subprocess is killed. |
| `work_dir` | `None` (temp dir per run) | Working directory for the script. |

`DockerExecutor` / `RDockerExecutor` (in `retally.codegen.docker_executor`):

| Parameter | Default | Description |
|---|---|---|
| `image` | `"retally-sandbox:latest"` / `"retally-sandbox-r:latest"` | Docker image tag. |
| `timeout` | `300` | Seconds before the container is killed. |
| `memory_limit` | `"4g"` | Docker `--memory` value. |
| `cpu_count` | `1.0` | Docker `--cpus` value. |

### `ResultComparator` tolerances

| Parameter | Default | Description |
|---|---|---|
| `default_tolerance` | `0.01` | Relative tolerance for `OTHER`-type claims. |

A claim passes when `|reproduced − claimed| / |claimed| ≤ tolerance`.
Per-type tolerances (not overridable without subclassing):

- **ML metrics:** `ACCURACY` / `F1_SCORE` / `AUC_ROC` / `PRECISION` /
  `RECALL` → 1 %; `RMSE` / `MAE` → 5 %; `CORRELATION` → 2 %;
  `P_VALUE` → 0.1 %; `EFFECT_SIZE` → 5 %.
- **Econometric quantities:** `COEFFICIENT` → 2 % (econ papers round
  coefficients more aggressively than ML metrics); `STANDARD_ERROR` → 5 %
  (heavily rounded in practice); `R_SQUARED` → 1 % (typical journal precision).

The comparator also handles **percentage vs. decimal mismatches**: if a paper
states "97.4%" and the code produces `0.974`, the claim passes with a note.

**Known limitation:** the `COEFFICIENT` tolerance is a flat relative
percentage, which becomes too tight for coefficients close to zero.
Standard-error-aware comparison (pass if within `±k·SE` of the reported
value) is a planned improvement — see [ROADMAP.md](../ROADMAP.md) §1.3.

---

## Hyperparameter audit

The pipeline checks whether the generated code actually used the
hyperparameters the paper specifies. `ClaimExtractor.extract_hyperparameters`
pulls every paper-stated hyperparameter into a structured `HyperparameterSpec`
(using the canonical scikit-learn keyword-argument name — `C`, `n_estimators`,
`random_state`, `test_size`, `hidden_layer_sizes`, `cv`, …). After Phase 1 and
Phase 2 settle, `validation.hyperparam_audit.audit_hyperparameters` walks the
AST of the final generated script and assigns each spec one of four statuses:

| Status | Meaning |
|---|---|
| `match` | Code used the paper's value (numeric comparison uses a small float tolerance; tuple/list containers are interchangeable). |
| `mismatch` | Code used a different literal value for this kwarg. |
| `not_found` | The kwarg never appears in any call. The code may still use the library default at runtime, but conformance cannot be proven from the AST. |
| `unresolved` | The kwarg is present but bound to a variable/expression that cannot be evaluated without executing the code. |

Results land on `ExecutionResult.hyperparameter_audits` and render in every
output format: a `## Hyperparameter audit` table in Markdown, a summary line
(`Hyperparameter audit: 3/4 matched`) plus one bullet per non-match on the
console, and a table in the demo dashboard's report modal.

**Caveat:** the audit is **independent of claim validation**. A paper can have
every claim pass while failing the audit — the model deviated from the stated
hyperparameters and happened to hit the number anyway — and vice versa. These
are different reproducibility questions, tracked separately on purpose.
`overall_passed` reflects only claim validation; the audit is informational.

---

## Reference-code baseline

Many ML papers ship the implementation that produced their numbers, usually as
a GitHub repository linked from the abstract or a "Code" section. When
`include_code_references=True` (the default), Retally:

1. **Extracts URLs.** `ClaimExtractor.extract_code_references` runs an LLM pass
   that finds repo links in the paper text and classifies each as `github` /
   `gitlab` / `bitbucket` / `zenodo` / `direct_url` / `unknown`. Non-code URLs
   (PDFs, dataset pages, personal homepages) are filtered out.
2. **Clones.** `CodeDownloader` shallow-clones GitHub repos
   (`--depth 1 --filter=blob:none`) into `.cache/code_repos/`. A
   `.retally-clone-complete` sentinel marks finished clones for later cache
   hits. Other hosts are recognised but not fetched yet — they appear in the
   report as "found but not fetched" so a reviewer knows the link exists.
3. **Selects relevant files.** `select_relevant_files` picks up to 20 files /
   200 KB of source per repo, preferring top-level Python scripts with names
   like `train.py`, `main.py`, `model.py`, `run.py`, `reproduce.py`,
   `experiment.py`. It skips `__init__.py`, tests, vendored deps, notebooks,
   examples, and any file larger than 20 KB.
4. **Seeds the generator.** The selected files appear in a
   `## Reference Implementation` section of the generation prompt, with the
   instruction to adapt the real code rather than reconstruct it from the
   methodology summary, swap dataset paths to `dataset.local_path/data.csv`,
   and omit experiments unrelated to the claims being reproduced.

Refinement prompts (Phase 1 and Phase 2) deliberately do **not** re-paste the
reference repo — they already have the previous code and the specific
error/gap to focus on. The reference is baked into the initial generation only.

Best-effort throughout: no code link → no extraction call; no URLs found → no
clone attempts; non-GitHub host → recorded but skipped; `git` missing → clone
skipped with a log line; clone fails → that reference contributes nothing. In
every case the pipeline continues and produces a report without a reference
baseline rather than crashing.

References (cloned or not) appear in the Markdown report as a
**Reference code** list under the dataset, and on the console as a
`Reference code: N/M cloned` summary line.

---

## Replication-package scripts

Econ replication packages (Zenodo/Dataverse archives) ship the authors' own
analysis scripts *inside the dataset* — the most authoritative description of
the estimating equation, variable names, sample restrictions, and clustering.
After the dataset downloads, `select_package_scripts` walks
`dataset.local_path` for `.R` / `.do` / `.Rmd` files, preferring names
containing `master` / `main` / `table` / `analysis` / `regression` /
`results` / `replicat` and demoting figure/plot scripts.

The generation prompt then gains an **Original Replication Scripts** section
instructing the model to implement the same specification — translating a
Stata `.do` regression into the equivalent `fixest::feols()` call rather than
transliterating syntax. Registry datasets contain no scripts, so the classic
ML flow is untouched. Like reference repos, the scripts go into the initial
generation only, not into refinement prompts.

---

## Docker sandbox details

| Flag | Effect |
|---|---|
| `--network none` | No outbound connections during code execution. |
| `--read-only` | Immutable container filesystem. |
| `--tmpfs /tmp:size=256m` | Writable scratch space in RAM only. |
| `--cap-drop ALL` | All Linux capabilities removed. |
| `--security-opt no-new-privileges` | No privilege escalation. |
| `--memory` / `--cpus` | Resource caps prevent runaway processes. |

The dataset is downloaded to the host by `DatasetDownloader` *before*
execution, then mounted read-only at its exact host path inside the container.
The images are built from `docker/Dockerfile.sandbox` and
`docker/Dockerfile.sandbox.r` and need no internet access once built.

- **Python image** (`retally-sandbox`): scikit-learn, xgboost, lightgbm,
  pandas, numpy, scipy, statsmodels, matplotlib.
- **R image** (`retally-sandbox-r`): fixest, AER, plm, lmtest, sandwich,
  modelsummary, plus jsonlite, data.table, readr, dplyr.

**Language routing.** `ValidationPipeline.default()` constructs both executors
and routes by `paper.language`: Python papers go to `DockerExecutor`, R papers
to `RDockerExecutor`. `CodeGenerator` likewise routes prompts: Python papers
get sklearn-flavoured prompts; R papers get econometrics prompts that favour
`feols` (fixest), `ivreg` (AER), `plm`, and robust/clustered standard errors.
Generated scripts in both languages emit the same `RESULT:<name>=<value>` and
`DEVIATION:<text>` stdout lines, so the output parser is language-agnostic.
Stata is not executed; the benchmark records Stata-only entries as typed skips
(see [`benchmark/README.md`](../benchmark/README.md)).

---

## Output

### `ValidationReport`

| Field | Type | Description |
|---|---|---|
| `paper` | `Paper` | Parsed paper (title, authors, claims, …). |
| `dataset` | `Dataset` | Downloaded dataset metadata. |
| `execution_result` | `ExecutionResult` | Generated code, stdout, stderr, exit code, deviation notes, hyperparameter audits. |
| `claim_results` | `list[ClaimValidationResult]` | Per-claim comparison. |
| `overall_passed` | `bool` | True only when every claim passes. |
| `summary` | `str` | One-line human summary. |

### `ClaimValidationResult`

| Field | Description |
|---|---|
| `claim.value` | Number stated in the paper. |
| `reproduced_value` | Number produced by the generated code (`None` if unmatched). |
| `tolerance` | Allowed relative error (default 1 %). |
| `passed` | True if within tolerance. |
| `notes` | Explanation of failures or unit-mismatch adjustments. |

### Saving reports

```python
from retally.validation.reporter import ValidationReporter

reporter = ValidationReporter()
reporter.save(report, "report.md")       # Markdown: claims table, generated code, stdout/stderr
reporter.save(report, "report.json")     # JSON
print(reporter.to_console(report))       # ANSI-coloured terminal output
print(reporter.to_markdown(report))      # Markdown string
```

---

## Supported datasets

The built-in registry pre-populates 28 classic datasets so papers that use
them need no manual URL. Lookups are case-insensitive by name.

**UCI ML Repository** (downloaded via `ucimlrepo`; install the `uci` extra):
Iris, Adult Income, Breast Cancer Wisconsin, Wine, Heart Disease, Ionosphere,
Sonar, Pima Indians Diabetes, German Credit, Letter Recognition, Mushroom,
Spambase, Abalone, Ecoli, Yeast, Glass Identification, Balance Scale,
Tic-Tac-Toe Endgame, Waveform, Zoo, Car Evaluation, Congressional Voting
Records, Soybean Large, Statlog Shuttle.

**Other sources:**

| Dataset | Source |
|---|---|
| MNIST | OpenML |
| Boston Housing | OpenML |
| California Housing | OpenML |
| Titanic | Kaggle |

The registry key is the lower-cased name (e.g. `breast cancer wisconsin`).

### Pinning the dataset for a run

If the extractor cannot find the dataset, or you want a specific version, pass
it explicitly:

```python
from retally import ValidationPipeline
from retally.models import DatasetReference, DatasetSource

pipeline = ValidationPipeline.default()
ref = DatasetReference(name="Breast Cancer Wisconsin", source=DatasetSource.UCI, url="17")  # UCI ID
report = pipeline.validate("path/to/paper.pdf", dataset_reference=ref)
```

### Adding a custom dataset to the registry

```python
from retally.models import DatasetReference, DatasetSource
from retally.dataset.registry import DatasetRegistry

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

## Pip-only install

The project is a standard PEP 621 package. Dev tooling lives in a PEP 735
dependency group, which pip ≥ 25.1 installs with:

```bash
pip install -e .
pip install --group dev
```

Older pips can still `pip install -e .` for the runtime dependencies; install
pytest, ruff, mypy, and types-requests manually.

---

## Architecture

```
src/retally/
├── models.py                  Shared dataclasses + enums (Language, ClaimType, …)
├── pipeline.py                ValidationPipeline orchestrator
├── llm_cache.py               CachingLLMClient (on-disk Claude call cache)
├── paper/
│   ├── parser.py              PaperParser (PDF, arXiv, DOI, URL, text)
│   └── extractor.py           ClaimExtractor (Claude-backed; claims,
│                              hyperparameters, code references)
├── dataset/
│   ├── registry.py            DatasetRegistry (JSON-backed, 28 builtins)
│   └── downloader.py          DatasetDownloader (UCI/Kaggle/Zenodo/OpenML/URL)
├── code/
│   ├── downloader.py          CodeDownloader (shallow git clone of paper repos)
│   └── selector.py            select_relevant_files (Python files from a cloned
│                              repo) + select_package_scripts (authors'
│                              .R/.do/.Rmd inside the replication package)
├── codegen/
│   ├── generator.py           CodeGenerator (Claude-backed; Python + R prompts)
│   ├── executor.py            CodeExecutor (subprocess; Python-only fallback)
│   └── docker_executor.py     DockerExecutor + RDockerExecutor (OS-level isolation)
└── validation/
    ├── comparator.py          ResultComparator (per-type tolerances)
    ├── hyperparam_audit.py    AST audit of generated code vs. paper-stated kwargs
    └── reporter.py            ValidationReporter (Markdown / JSON / console)

docker/
├── Dockerfile.sandbox         Offline Python ML sandbox image
├── Dockerfile.sandbox.r       Offline R econometrics sandbox image
├── requirements.sandbox.txt   Pinned Python packages
└── requirements.sandbox.r.txt Pinned R packages

benchmark/                     I4R replication benchmark harness (see its README)
├── papers/                    Per-paper YAML catalog (one entry per I4R report)
├── corpus/                    I4R meta-database used for candidate intake
├── schema.py                  BenchmarkEntry loader (validates catalog YAML)
├── runner.py                  Drives ValidationPipeline across the catalog
├── metrics.py                 Closeness metrics (relative error, tolerance bands)
├── compare.py                 Keep-or-revert diff between two results.json runs
├── report.py                  Renders REPORT.md + report.html
└── results/REPORT.md          Committed run summary

scripts/
└── import_i4r_candidates.py   Emits prefilled candidate YAMLs from the I4R corpus

docs/
├── index.html                 Demo dashboard (synthetic inputs; not real verdicts)
└── reference.md               This page

tests/                         pytest suite (network/Docker/no-API-key tests auto-skip)
Makefile                       sync / test / lint / typecheck / check / benchmark /
                               build-sandbox / build-r-sandbox
```
