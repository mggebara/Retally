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
    assert "/tmp/iris/data.csv" in prompt


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

    hint = CodeGenerator._algorithm_hint_r({ClaimType.OTHER})
    assert "fixest" in hint


def test_algorithm_hint_r_does_not_mention_sklearn():
    from openra.codegen.generator import CodeGenerator
    from openra.models import ClaimType

    hint = CodeGenerator._algorithm_hint_r({ClaimType.RMSE})
    assert "sklearn" not in hint.lower()
    assert "scikit" not in hint.lower()
