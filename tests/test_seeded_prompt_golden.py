"""Golden-file guard: a seeded run's generation prompt is byte-identical.

The ``reproduction_mode`` switch (seeded vs independent) must not move a
single byte of the prompt that the default (seeded) path sends — the
benchmark's existing LLM cache, its baselines, and every comparison
against earlier runs depend on that.  The golden files under
``tests/fixtures/seeded_prompt/`` were captured from the generator
*before* the mode switch existed, using exactly the builder below.

The fixture package is a miniature replication archive (a CSV, a Stata
``master.do``, an R script), so the prompt exercises every section that
seeding touches: the dataset listing, the reference-implementation block,
and the original-replication-scripts block.  The absolute dataset path is
machine-specific, so it is replaced with ``<DATASET_ROOT>`` on both sides.

To regenerate deliberately (i.e. you *meant* to change the seeded
prompt), run ``RETALLY_REGEN_GOLDEN=1 uv run pytest tests/test_seeded_prompt_golden.py``
and justify the diff in the PR.
"""

from __future__ import annotations

import os
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from retally.code.selector import SelectedFile, select_package_scripts
from retally.codegen.generator import CodeGenerator
from retally.models import Claim, ClaimType, Dataset, Language, Paper, ReproductionMode

FIXTURE_DIR = Path(__file__).parent / "fixtures" / "seeded_prompt"
PACKAGE_DIR = FIXTURE_DIR / "package"


def _paper(language: Language) -> Paper:
    return Paper(
        title="Warfare and Development in India",
        abstract="We study the long-run effect of precolonial warfare on development.",
        full_text="",
        claims=[
            Claim(
                description="warfare_coefficient_bivariate",
                value=3.713,
                claim_type=ClaimType.COEFFICIENT,
            ),
            Claim(description="n_districts", value=660, claim_type=ClaimType.OTHER),
        ],
        methodology_summary="OLS of night lights on conflict counts with state fixed effects.",
        language=language,
    )


def _dataset() -> Dataset:
    return Dataset(name="wii-package", source_url="https://zenodo.org/records/1", local_path=PACKAGE_DIR)


def _captured_prompt(language: Language, **generate_kwargs) -> str:
    """Drive the public ``generate()`` with a mocked client and return the prompt it sent."""
    client = MagicMock()
    client.messages.create.return_value = MagicMock(content=[MagicMock(text="x <- 1")])
    gen = CodeGenerator(client)
    gen.generate(
        _paper(language),
        _dataset(),
        reference_files=[SelectedFile(relative_path="src/model.R", contents="lm(y ~ x)")],
        package_scripts=select_package_scripts(PACKAGE_DIR),
        **generate_kwargs,
    )
    prompt = client.messages.create.call_args.kwargs["messages"][0]["content"]
    return prompt.replace(str(PACKAGE_DIR.resolve()), "<DATASET_ROOT>")


@pytest.mark.parametrize("language", [Language.R, Language.PYTHON], ids=["r", "python"])
def test_default_generation_prompt_matches_pre_mode_golden(language):
    golden = FIXTURE_DIR / f"generation_prompt_{language.value}.txt"
    prompt = _captured_prompt(language)
    if os.environ.get("RETALLY_REGEN_GOLDEN") == "1":
        golden.write_text(prompt, encoding="utf-8")
    assert prompt == golden.read_text(encoding="utf-8")


@pytest.mark.parametrize("language", [Language.R, Language.PYTHON], ids=["r", "python"])
def test_explicit_seeded_mode_matches_golden(language):
    """Passing ``reproduction_mode=SEEDED`` explicitly is the same as the default."""
    golden = FIXTURE_DIR / f"generation_prompt_{language.value}.txt"
    prompt = _captured_prompt(language, reproduction_mode=ReproductionMode.SEEDED)
    assert prompt == golden.read_text(encoding="utf-8")
