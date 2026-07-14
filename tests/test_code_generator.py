"""Tests for CodeGenerator prompt construction.

These tests target the deterministic prompt-building paths and never
hit the Anthropic API.  Behaviour around the optional
``reference_files`` parameter is the main focus — it landed in the
PR that introduced paper-linked code baselines.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest

from openra.code.selector import SelectedFile
from openra.codegen.generator import CodeGenerator, UnsupportedLanguageError
from openra.models import Claim, ClaimType, Dataset, ExecutionResult, Language, Paper


def _paper(**overrides):
    base = {
        "title": "Test Paper",
        "abstract": "We classify things.",
        "full_text": "",
        "claims": [Claim(description="accuracy", value=0.95, claim_type=ClaimType.ACCURACY)],
        "methodology_summary": "Logistic regression on the iris dataset.",
    }
    base.update(overrides)
    return Paper(**base)


def _dataset():
    return Dataset(
        name="iris",
        source_url="ucimlrepo://53",
        local_path=Path("/tmp/iris"),
    )


def _generator():
    # The Anthropic client is only touched by ``generate()``, not by the
    # private prompt builders we're exercising.  A MagicMock satisfies
    # the constructor type.
    return CodeGenerator(MagicMock())


def _selected(rel: str, contents: str) -> SelectedFile:
    return SelectedFile(relative_path=rel, contents=contents)


# ── No reference files ────────────────────────────────────────────────


def test_prompt_omits_reference_section_when_no_files():
    gen = _generator()
    prompt = gen._build_generation_prompt_python(_paper(), _dataset(), reference_files=[])
    assert "## Reference Implementation" not in prompt
    assert "PREFER ADAPTING" not in prompt


def test_generate_passes_default_empty_reference_files():
    """generate() must work without the new kwarg (backwards compat)."""
    gen = _generator()
    # Mock the LLM call so we don't hit the network.
    msg = MagicMock()
    msg.content = [MagicMock(text="```python\nprint('RESULT:accuracy=0.5')\n```")]
    gen._client.messages.create.return_value = msg

    code = gen.generate(_paper(), _dataset())
    assert "RESULT:accuracy=0.5" in code


# ── With reference files ──────────────────────────────────────────────


def test_prompt_includes_reference_section_when_files_present():
    gen = _generator()
    files = [_selected("train.py", "# real training script\nx = 1\n")]
    prompt = gen._build_generation_prompt_python(_paper(), _dataset(), reference_files=files)
    assert "## Reference Implementation" in prompt
    assert "PREFER ADAPTING" in prompt
    assert "### `train.py`" in prompt
    assert "# real training script" in prompt


def test_prompt_renders_multiple_files_in_order():
    gen = _generator()
    files = [
        _selected("train.py", "TRAIN_FILE"),
        _selected("model.py", "MODEL_FILE"),
        _selected("src/utils.py", "UTILS_FILE"),
    ]
    prompt = gen._build_generation_prompt_python(_paper(), _dataset(), reference_files=files)
    train_pos = prompt.index("TRAIN_FILE")
    model_pos = prompt.index("MODEL_FILE")
    utils_pos = prompt.index("UTILS_FILE")
    # Order in the prompt mirrors the input order (selector decides ranking).
    assert train_pos < model_pos < utils_pos


def test_prompt_tells_model_to_swap_dataset_path():
    gen = _generator()
    files = [_selected("train.py", "df = pd.read_csv('data/iris.csv')")]
    prompt = gen._build_generation_prompt_python(_paper(), _dataset(), reference_files=files)
    # The dataset's actual local_path should appear in the override
    # instruction so the model knows where to point read_csv calls.
    # (Wording changed when the prompt became dataset-tree-aware: it now
    # points at the file listing rather than hardcoding data.csv.)
    assert "/tmp/iris" in prompt
    assert "instead of whatever paths the" in prompt


def test_generate_forwards_reference_files_to_prompt():
    gen = _generator()
    files = [_selected("train.py", "ADAPT_ME")]
    msg = MagicMock()
    msg.content = [MagicMock(text="```python\nprint('ok')\n```")]
    gen._client.messages.create.return_value = msg

    gen.generate(_paper(), _dataset(), reference_files=files)
    # The prompt passed to the LLM must include the reference file body.
    [call] = gen._client.messages.create.call_args_list
    sent_prompt = call.kwargs["messages"][0]["content"]
    assert "ADAPT_ME" in sent_prompt


# ── Language guard ────────────────────────────────────────────────────


def test_generate_rejects_stata_paper():
    gen = _generator()
    paper = _paper(language=Language.STATA)
    with pytest.raises(UnsupportedLanguageError, match="language=stata"):
        gen.generate(paper, _dataset())


def test_generate_rejects_unknown_language():
    gen = _generator()
    paper = _paper(language=Language.UNKNOWN)
    with pytest.raises(UnsupportedLanguageError, match="language=unknown"):
        gen.generate(paper, _dataset())


def test_generate_accepts_python_explicitly():
    """The default and the explicit PYTHON setting should behave identically."""
    gen = _generator()
    msg = MagicMock()
    msg.content = [MagicMock(text="```python\nprint('ok')\n```")]
    gen._client.messages.create.return_value = msg
    code = gen.generate(_paper(language=Language.PYTHON), _dataset())
    assert "ok" in code


def test_refine_rejects_stata():
    gen = _generator()
    paper = _paper(language=Language.STATA)
    with pytest.raises(UnsupportedLanguageError, match="refine.*language=stata"):
        gen.refine("code", "error", paper, _dataset())


def test_refine_for_claims_rejects_stata():
    gen = _generator()
    paper = _paper(language=Language.STATA)
    exec_result = ExecutionResult(generated_code="x")
    with pytest.raises(UnsupportedLanguageError, match="refine_for_claims.*language=stata"):
        gen.refine_for_claims("code", [], exec_result, paper, _dataset(), [])


# ── R prompt construction ─────────────────────────────────────────────


def test_generate_routes_to_r_prompt_when_language_r():
    gen = _generator()
    msg = MagicMock()
    msg.content = [MagicMock(text="```r\ncat('RESULT:beta=0.1\\n')\n```")]
    gen._client.messages.create.return_value = msg

    paper = _paper(language=Language.R)
    code = gen.generate(paper, _dataset())
    assert "RESULT:beta=0.1" in code

    # The prompt sent to the LLM is R-flavoured.
    [call] = gen._client.messages.create.call_args_list
    sent_prompt = call.kwargs["messages"][0]["content"]
    assert "Write R code" in sent_prompt
    assert "fixest" in sent_prompt  # algorithm hint or code requirements
    assert "cat('RESULT:" in sent_prompt  # R output convention example


def test_r_prompt_omits_python_specific_libraries():
    """The R prompt must NOT instruct the model to use sklearn / pandas."""
    gen = _generator()
    paper = _paper(language=Language.R)
    prompt = gen._build_generation_prompt_r(paper, _dataset(), reference_files=[])
    assert "scikit-learn" not in prompt
    assert "pandas" not in prompt
    assert "random_state=42" not in prompt  # python idiom
    assert "set.seed(42)" in prompt  # R equivalent


def test_r_prompt_references_econometrics_packages():
    gen = _generator()
    paper = _paper(language=Language.R)
    prompt = gen._build_generation_prompt_r(paper, _dataset(), reference_files=[])
    # Each of the headline packages should appear somewhere in the prompt
    # so the model knows what's available.
    for pkg in ["fixest", "AER", "plm", "lmtest", "sandwich"]:
        assert pkg in prompt, f"R prompt should mention {pkg}"


def test_r_prompt_uses_r_code_fence_for_reference_files():
    gen = _generator()
    paper = _paper(language=Language.R)
    files = [_selected("train.R", "library(fixest)\n# real reference\n")]
    prompt = gen._build_generation_prompt_r(paper, _dataset(), reference_files=files)
    assert "```r" in prompt
    assert "```python" not in prompt
    assert "library(fixest)" in prompt


def test_python_prompt_uses_python_code_fence_for_reference_files():
    """Regression: the Python builder must still emit ```python fences."""
    gen = _generator()
    paper = _paper(language=Language.PYTHON)
    files = [_selected("train.py", "import sklearn\n")]
    prompt = gen._build_generation_prompt_python(paper, _dataset(), reference_files=files)
    assert "```python" in prompt
    assert "```r" not in prompt


def test_refine_routes_to_r_prompt():
    gen = _generator()
    msg = MagicMock()
    msg.content = [MagicMock(text="```r\ncat('RESULT:x=1\\n')\n```")]
    gen._client.messages.create.return_value = msg

    paper = _paper(language=Language.R)
    gen.refine("old R code", "Error: object 'x' not found", paper, _dataset())

    [call] = gen._client.messages.create.call_args_list
    sent_prompt = call.kwargs["messages"][0]["content"]
    assert "R code" in sent_prompt
    assert "Rscript" not in sent_prompt or "library(" in sent_prompt or "cat(" in sent_prompt
    # The "old R code" body must appear so the model can edit it.
    assert "old R code" in sent_prompt


def test_refine_for_claims_routes_to_r_prompt():
    gen = _generator()
    msg = MagicMock()
    msg.content = [MagicMock(text="```r\ncat('RESULT:x=1\\n')\n```")]
    gen._client.messages.create.return_value = msg

    paper = _paper(language=Language.R)
    exec_result = ExecutionResult(generated_code="code", outputs={"beta": 0.3})
    from openra.models import Claim, ClaimType, ClaimValidationResult

    failed = ClaimValidationResult(
        claim=Claim(description="treatment", value=0.5, claim_type=ClaimType.OTHER),
        reproduced_value=0.3,
        tolerance=0.01,
        passed=False,
    )
    gen.refine_for_claims("v1", [failed], exec_result, paper, _dataset(), [{"beta": 0.3}])

    [call] = gen._client.messages.create.call_args_list
    sent_prompt = call.kwargs["messages"][0]["content"]
    assert "R code" in sent_prompt
    assert "cat('DEVIATION:" in sent_prompt  # R-syntax deviation example
    assert "treatment" in sent_prompt  # failed claim surfaces


# ── Algorithm hints, per language ─────────────────────────────────────


def test_algorithm_hint_python_mentions_sklearn():
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType

    hint = CodeGenerator._algorithm_hint_python({ClaimType.ACCURACY})
    assert "scikit-learn" in hint.lower() or "sklearn" in hint.lower() or "Support Vector" in hint


def test_algorithm_hint_r_mentions_fixest():
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType

    # COEFFICIENT is the trigger for the default fixest guidance post-PR 5;
    # an empty claim set also fires it (no claims → assume regression).
    hint = CodeGenerator._algorithm_hint_r({ClaimType.COEFFICIENT})
    assert "fixest" in hint


def test_algorithm_hint_r_does_not_mention_sklearn():
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType

    hint = CodeGenerator._algorithm_hint_r({ClaimType.RMSE})
    assert "sklearn" not in hint.lower()
    assert "scikit" not in hint.lower()


# ── Econometric claim type hints (PR 5) ────────────────────────────────


def test_algorithm_hint_python_reacts_to_coefficient_claims():
    """COEFFICIENT in the claim set should trigger statsmodels guidance."""
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType as CT

    hint = CodeGenerator._algorithm_hint_python({CT.COEFFICIENT})
    assert "statsmodels" in hint
    assert "OLS" in hint or "ols" in hint.lower()


def test_algorithm_hint_python_reacts_to_r_squared_claims():
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType as CT

    hint = CodeGenerator._algorithm_hint_python({CT.R_SQUARED})
    assert "statsmodels" in hint


def test_algorithm_hint_python_does_not_emit_econ_block_for_pure_accuracy():
    """Pure ACCURACY claim shouldn't pull in the statsmodels guidance."""
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType as CT

    hint = CodeGenerator._algorithm_hint_python({CT.ACCURACY})
    assert "statsmodels" not in hint


def test_algorithm_hint_r_emits_r_squared_specific_guidance():
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType as CT

    hint = CodeGenerator._algorithm_hint_r({CT.R_SQUARED})
    assert "r2(model)" in hint or "r.squared" in hint


def test_algorithm_hint_r_no_longer_fires_for_pure_accuracy():
    """The R hint used to emit the default coefficient guidance for every
    paper.  Post-PR 5 it only fires for econometric / empty claim sets.
    """
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType as CT

    hint = CodeGenerator._algorithm_hint_r({CT.ACCURACY})
    # The default fixest guidance shouldn't dominate when the paper's
    # claims are pure ACCURACY (which is unusual for R papers but still
    # well-defined).
    assert "fixest::feols" not in hint


# ── Code-block extraction (markdown fence stripping) ─────────────────


@pytest.mark.parametrize(
    "fence_tag",
    ["python", "py", "r", "R", ""],
)
def test_extract_code_block_strips_language_fence(fence_tag):
    """All four language tags plus a bare fence must extract cleanly.

    Regression: the original regex only matched ``python`` or bare ``,
    so an R-fenced response was returned verbatim — markdown prose and
    all — and shipped to the executor as code.  Every R paper would have
    failed at the generation step.
    """
    gen = _generator()
    body = "library(fixest)\nfeols(y ~ x, data = df)\n"
    response = f"Sure, here's the script:\n\n```{fence_tag}\n{body}```\nLet me know.\n"
    assert gen._extract_code_block(response) == body.strip()


def test_extract_code_block_returns_raw_when_no_fence():
    gen = _generator()
    assert gen._extract_code_block("  print(1)\n") == "print(1)"


# ── Dataset file listing / load instruction ────────────────────────────


def _tree_dataset(tmp_path: Path) -> Dataset:
    """A replication-package-style dataset: nested tree, no data.csv."""
    (tmp_path / "code").mkdir()
    (tmp_path / "data").mkdir()
    (tmp_path / "data" / "conflicts.dta").write_bytes(b"\x00" * 2048)
    (tmp_path / "data" / "districts.csv").write_text("district_id,luminosity,battles_250km\n1,0.5,3\n")
    (tmp_path / "code" / "main_analysis.R").write_text("# analysis\n")
    (tmp_path / ".hidden_state").write_text("skip me")
    return Dataset(name="pkg", source_url="", local_path=tmp_path)


def test_dataset_section_lists_files_in_tree(tmp_path):
    gen = _generator()
    section = "\n".join(gen._dataset_section(_tree_dataset(tmp_path)))
    assert "data/conflicts.dta" in section
    assert "code/main_analysis.R" in section
    # CSV headers surface so the model knows the real column names.
    assert "district_id,luminosity,battles_250km" in section
    # Hidden files stay out of the prompt.
    assert ".hidden_state" not in section


def test_dataset_file_listing_truncates_past_cap(tmp_path):
    from openra.codegen.generator import _TREE_MAX_FILES, _describe_dataset_files

    for i in range(_TREE_MAX_FILES + 5):
        (tmp_path / f"file_{i:03d}.txt").write_text("x")
    lines = _describe_dataset_files(tmp_path)
    assert len(lines) == _TREE_MAX_FILES + 1  # entries + truncation marker
    assert "5 more files" in lines[-1]


def test_dataset_file_listing_empty_for_missing_dir(tmp_path):
    from openra.codegen.generator import _describe_dataset_files

    assert _describe_dataset_files(tmp_path / "nope") == []


def test_load_instruction_keeps_data_csv_for_registry_datasets(tmp_path):
    """Single-data.csv datasets (the registry-download shape) keep the
    original explicit path so nothing changes for the Python/ML flow."""
    (tmp_path / "data.csv").write_text("a,b\n1,2\n")
    ds = Dataset(name="iris", source_url="", local_path=tmp_path)
    py = CodeGenerator._load_instruction(ds, Language.PYTHON)
    r = CodeGenerator._load_instruction(ds, Language.R)
    assert f"{tmp_path}/data.csv" in py and "pandas" in py
    assert f"{tmp_path}/data.csv" in r and "read.csv" in r


def test_load_instruction_points_at_tree_when_no_data_csv(tmp_path):
    """Replication packages have no data.csv — the instruction must not
    invent one (that's what sank the first benchmark run) and should
    name the format-appropriate readers."""
    ds = _tree_dataset(tmp_path)
    py = CodeGenerator._load_instruction(ds, Language.PYTHON)
    r = CodeGenerator._load_instruction(ds, Language.R)
    assert "data.csv" not in py and "read_stata" in py
    assert "data.csv" not in r and "haven::read_dta" in r


def test_r_generation_prompt_embeds_file_tree_not_data_csv(tmp_path):
    """End-to-end at the prompt level: an R generation prompt for a tree
    dataset must contain the real file paths and no data.csv fiction."""
    gen = _generator()
    paper = _paper(language=Language.R)
    prompt = gen._build_generation_prompt_r(paper, _tree_dataset(tmp_path), reference_files=[])
    assert "data/conflicts.dta" in prompt
    assert "data.csv" not in prompt


def test_prompt_dataset_path_is_absolute_matching_the_mount():
    """The prompt must name the path the sandbox actually mounts the data
    at.  ``dataset.local_path`` is relative (the downloader caches under
    ``.cache/datasets``) but RDockerExecutor mounts at
    ``local_path.resolve()`` with workdir /workspace, so a relative path in
    the prompt makes the generated code look in the wrong place and stop
    with "No .dta or .csv files found".  Every embedded dataset path must be
    the resolved absolute path."""
    rel = Path(".cache/datasets/some_pkg")
    ds = Dataset(name="pkg", source_url="", local_path=rel)
    mount = rel.resolve()  # what the executor mounts and cds workdir alongside

    for lang in (Language.R, Language.PYTHON):
        instr = CodeGenerator._load_instruction(ds, lang)
        assert str(mount) in instr
        # The bare relative path must not be handed to the model as the base.
        assert f"at '{rel}'" not in instr and f"at {rel} " not in instr

    section = "\n".join(CodeGenerator._dataset_section(CodeGenerator.__new__(CodeGenerator), ds))
    assert f"Local path: {mount}" in section
