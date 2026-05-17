"""Tests for CodeGenerator prompt construction.

These tests target the deterministic prompt-building paths and never
hit the Anthropic API.  Behaviour around the optional
``reference_files`` parameter is the main focus — it landed in the
PR that introduced paper-linked code baselines.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

from openra.code.selector import SelectedFile
from openra.codegen.generator import CodeGenerator
from openra.models import Claim, ClaimType, Dataset, Paper


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
    prompt = gen._build_generation_prompt(_paper(), _dataset(), reference_files=[])
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
    prompt = gen._build_generation_prompt(_paper(), _dataset(), reference_files=files)
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
    prompt = gen._build_generation_prompt(_paper(), _dataset(), reference_files=files)
    train_pos = prompt.index("TRAIN_FILE")
    model_pos = prompt.index("MODEL_FILE")
    utils_pos = prompt.index("UTILS_FILE")
    # Order in the prompt mirrors the input order (selector decides ranking).
    assert train_pos < model_pos < utils_pos


def test_prompt_tells_model_to_swap_dataset_path():
    gen = _generator()
    files = [_selected("train.py", "df = pd.read_csv('data/iris.csv')")]
    prompt = gen._build_generation_prompt(_paper(), _dataset(), reference_files=files)
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
