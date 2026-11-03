"""Manually placed packages: ``data_access: manual`` and ``DatasetSource.LOCAL``.

A human downloads a package the harness cannot fetch (openICPSR: login and
terms click-through) and drops the zip under ``benchmark/manual-packages/<tag>/``.
Covered here, with a tiny synthetic zip under ``tmp_path``:

* the downloader extracts a placed archive (or copies a directory) into the
  cache, leaves the placed file alone, writes the sentinel and records the
  path, size and sha256 in ``metadata.json``; zip-slip is still refused;
* the schema parses ``data_access`` and rejects a local path without
  ``manual`` and ``manual`` with a URL;
* the runner maps an existing local source to ``LOCAL``, skips a manual entry
  whose file is missing with a message naming the file, and stamps
  ``data_access`` on every row;
* a manual zip goes through render_task's strip + mount exactly like the
  same package fetched from Zenodo.

No network, no Docker, no API key.
"""

from __future__ import annotations

import hashlib
import json
import zipfile
from pathlib import Path

import pytest

from retally.dataset.downloader import _COMPLETE_SENTINEL, DatasetDownloader
from retally.models import DatasetReference, DatasetSource
from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")
strip_rule = load_module_from_path("benchmark.strip_rule", REPO_ROOT / "benchmark" / "strip_rule.py")
render_mod = load_module_from_path(
    "benchmark.reproducers.render_task", REPO_ROOT / "benchmark" / "reproducers" / "render_task.py"
)

PACKAGE_DIR = Path(__file__).parent / "fixtures" / "seeded_prompt" / "package"


def _zip_package(zip_path: Path, root: Path = PACKAGE_DIR, prefix: str = "") -> Path:
    """Zip ``root`` (optionally under a top-level ``prefix/`` folder, as openICPSR zips are)."""
    zip_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path, "w") as zf:
        for p in sorted(root.rglob("*")):
            if p.is_file():
                zf.write(p, prefix + p.relative_to(root).as_posix())
    return zip_path


def _entry(**overrides):
    base = {
        "id": "manual-paper",
        "i4r_report_url": "https://example.org/r",
        "language": bschema.Language.R,
        "outcome_label": bschema.OutcomeLabel.REPRODUCIBLE,
        "paper": bschema.PaperRef(source="fixture paper text", title="Warfare and Development"),
        "original_claims": [
            bschema.OriginalClaim(description="beta", value=3.713, claim_type="coefficient"),
        ],
    }
    base.update(overrides)
    return bschema.BenchmarkEntry(**base)


def _manual(source: str, notes: str = "openICPSR 149882 V1") -> bschema.DatasetRef:
    return bschema.DatasetRef(source=source, access_notes=notes, data_access="manual")


# ── Downloader ──────────────────────────────────────────────────────────


def test_local_zip_is_extracted_with_sentinel_and_provenance(tmp_path):
    placed = _zip_package(tmp_path / "manual-packages" / "T73" / "149882-V1.zip")
    before = placed.read_bytes()
    ref = DatasetReference(name="T73", source=DatasetSource.LOCAL, url=str(placed))

    ds = DatasetDownloader(cache_dir=tmp_path / "datasets").download(ref)

    dest = Path(ds.local_path)
    assert (dest / "code" / "master.do").is_file() and (dest / "data" / "analysis.csv").is_file()
    assert (dest / _COMPLETE_SENTINEL).exists()
    assert not (dest / placed.name).exists()  # the staged copy is gone ...
    assert placed.read_bytes() == before  # ... and the placed file untouched
    assert ds.metadata == {
        "source": "local",
        "data_access": "manual",
        "source_path": str(placed),
        "kind": "archive",
        "size_bytes": len(before),
        "sha256": hashlib.sha256(before).hexdigest(),
    }


def test_local_relative_path_resolves_against_the_repo_root(tmp_path, monkeypatch):
    placed = _zip_package(tmp_path / "pkg.zip")
    monkeypatch.setattr("retally.dataset.downloader._REPO_ROOT", tmp_path / "repo")
    (tmp_path / "repo").mkdir()
    (tmp_path / "repo" / "pyproject.toml").write_text("", encoding="utf-8")
    (tmp_path / "repo" / "benchmark" / "manual-packages" / "T1").mkdir(parents=True)
    placed.rename(tmp_path / "repo" / "benchmark" / "manual-packages" / "T1" / "pkg.zip")
    monkeypatch.chdir(tmp_path)  # not the root: the path must not resolve against cwd

    ref = DatasetReference(name="T1", source=DatasetSource.LOCAL, url="benchmark/manual-packages/T1/pkg.zip")
    ds = DatasetDownloader(cache_dir=tmp_path / "datasets").download(ref)
    assert (Path(ds.local_path) / "code" / "master.do").is_file()
    assert ds.metadata["source_path"] == "benchmark/manual-packages/T1/pkg.zip"


def test_local_directory_is_copied(tmp_path):
    ref = DatasetReference(name="dir", source=DatasetSource.LOCAL, url=str(PACKAGE_DIR))
    ds = DatasetDownloader(cache_dir=tmp_path / "datasets").download(ref)
    dest = Path(ds.local_path)
    assert (dest / "code" / "main_tables.R").is_file()
    assert ds.metadata["kind"] == "directory"
    assert ds.metadata["size_bytes"] == sum(p.stat().st_size for p in PACKAGE_DIR.rglob("*") if p.is_file())
    assert len(ds.metadata["sha256"]) == 64


def test_local_zip_slip_is_refused_and_not_marked_complete(tmp_path):
    bad = tmp_path / "evil.zip"
    with zipfile.ZipFile(bad, "w") as zf:
        zf.writestr("../escaped.txt", "x")
    ref = DatasetReference(name="evil", source=DatasetSource.LOCAL, url=str(bad))
    downloader = DatasetDownloader(cache_dir=tmp_path / "datasets")
    with pytest.raises(RuntimeError, match="could not extract manually placed archive"):
        downloader.download(ref)
    assert not (tmp_path / "datasets" / "escaped.txt").exists()
    assert not (downloader._local_path(ref) / _COMPLETE_SENTINEL).exists()
    assert bad.is_file()


def test_local_missing_file_fails_naming_the_path(tmp_path):
    ref = DatasetReference(name="gone", source=DatasetSource.LOCAL, url=str(tmp_path / "nope.zip"))
    with pytest.raises(RuntimeError, match="manually placed package not found: .*nope.zip"):
        DatasetDownloader(cache_dir=tmp_path / "datasets").download(ref)


# ── Schema ──────────────────────────────────────────────────────────────


_YAML = """\
id: t73
i4r_report_url: https://example.org/r
language: r
outcome_label: reproducible
paper:
  source: https://example.org/paper.pdf
dataset:
{dataset}
"""


def _load(tmp_path, dataset: str):
    p = tmp_path / "t73.yaml"
    p.write_text(_YAML.format(dataset=dataset), encoding="utf-8")
    return bschema.load_entry(p)


def test_schema_parses_manual_data_access(tmp_path):
    entry = _load(
        tmp_path,
        "  source: benchmark/manual-packages/T73/149882-V1.zip\n"
        "  data_access: manual\n"
        "  access_notes: openICPSR project 149882, version V1",
    )
    assert entry.dataset.data_access == "manual"
    assert entry.dataset.source == "benchmark/manual-packages/T73/149882-V1.zip"


def test_schema_defaults_to_public(tmp_path):
    assert _load(tmp_path, "  source: https://zenodo.org/records/1").dataset.data_access == "public"
    # A registry id and a TODO placeholder are not local paths.
    assert _load(tmp_path, "  source: iris").dataset.data_access == "public"
    assert _load(tmp_path, '  source: "TODO: open dataset URL (Zenodo / Dataverse) — see"').dataset


def test_schema_rejects_a_local_path_without_manual(tmp_path):
    with pytest.raises(
        bschema.SchemaError, match="is a local path; a manually placed package needs 'data_access: manual'"
    ):
        _load(tmp_path, "  source: benchmark/manual-packages/T73/149882-V1.zip")


def test_schema_rejects_manual_with_a_url(tmp_path):
    with pytest.raises(bschema.SchemaError, match="'manual' but dataset.source is a URL"):
        _load(
            tmp_path,
            "  source: https://www.openicpsr.org/openicpsr/project/149882/version/V1/view\n"
            "  data_access: manual",
        )


def test_schema_rejects_an_unknown_data_access(tmp_path):
    with pytest.raises(bschema.SchemaError, match="data_access must be one of"):
        _load(tmp_path, "  source: https://zenodo.org/records/1\n  data_access: restricted")


# ── Runner ──────────────────────────────────────────────────────────────


def test_existing_local_source_maps_to_local(tmp_path):
    placed = _zip_package(tmp_path / "pkg.zip")
    ref = runner._dataset_reference_for(_entry(dataset=_manual(str(placed))))
    assert ref.source is DatasetSource.LOCAL
    assert ref.url == str(placed)


def test_relative_manual_source_resolves_against_repo_root_and_stays_relative(tmp_path, monkeypatch):
    monkeypatch.setattr(runner, "REPO_ROOT", tmp_path)
    _zip_package(tmp_path / "benchmark" / "manual-packages" / "T73" / "149882-V1.zip")
    ref = runner._dataset_reference_for(
        _entry(dataset=_manual("benchmark/manual-packages/T73/149882-V1.zip"))
    )
    assert ref.source is DatasetSource.LOCAL
    assert ref.url == "benchmark/manual-packages/T73/149882-V1.zip"


def test_public_sources_are_unchanged():
    ref = runner._dataset_reference_for(
        _entry(dataset=bschema.DatasetRef(source="https://zenodo.org/records/1"))
    )
    assert ref.source is DatasetSource.ZENODO
    ref = runner._dataset_reference_for(_entry(dataset=bschema.DatasetRef(source="iris")))
    assert ref.source is DatasetSource.UNKNOWN


def test_missing_manual_package_is_a_skip_naming_the_file(tmp_path, monkeypatch):
    monkeypatch.setattr(runner, "REPO_ROOT", tmp_path)
    entry = _entry(dataset=_manual("benchmark/manual-packages/T73/149882-V1.zip"))

    def _factory():
        raise AssertionError("a skipped entry must not build a reproducer")

    row = runner._run_one(entry, reproducer_factory=_factory, cache_dir=tmp_path / "cache", use_cache=True)
    assert row.skipped and row.skip_reason is runner.SkipReason.MANUAL_PACKAGE_MISSING
    assert row.data_access == "manual"
    assert "expected benchmark/manual-packages/T73/149882-V1.zip" in row.error
    assert "SOURCE.txt beside it in benchmark/manual-packages/T73/" in row.error
    assert "openICPSR 149882 V1" in row.error
    # render_task goes through _dataset_reference_for, which fails loudly with the same message.
    with pytest.raises(FileNotFoundError, match="expected benchmark/manual-packages/T73/149882-V1.zip"):
        runner._dataset_reference_for(entry)


def test_every_row_carries_data_access(tmp_path):
    placed = _zip_package(tmp_path / "pkg.zip")

    def _factory():
        raise RuntimeError("no docker")

    manual = runner._run_one(
        _entry(dataset=_manual(str(placed))), reproducer_factory=_factory, cache_dir=tmp_path, use_cache=False
    )
    assert manual.skip_reason is runner.SkipReason.REPRODUCER_INIT_FAILED and manual.data_access == "manual"
    public = runner._run_one(_entry(), reproducer_factory=_factory, cache_dir=tmp_path, use_cache=False)
    assert public.data_access == "public"

    back = runner._result_from_jsonable(json.loads(json.dumps(runner._result_to_jsonable(manual))))
    assert back.data_access == "manual"
    # Rows from files that predate the field read as public.
    assert runner._result_from_jsonable({"entry_id": "x"}).data_access == "public"


def test_data_access_is_not_part_of_the_cache_key(monkeypatch):
    """A manual package and a public one, otherwise identical, share a cache key in every pipeline state."""
    public = _entry(dataset=bschema.DatasetRef(source="https://zenodo.org/records/1"))
    relabelled = _entry(
        dataset=bschema.DatasetRef(source="https://zenodo.org/records/1", data_access="manual")
    )
    monkeypatch.delenv(runner.PIPELINE_FROZEN_ENV, raising=False)
    post_fix = runner._cache_key(public)
    assert post_fix == runner._cache_key(relabelled)
    monkeypatch.setenv(runner.PIPELINE_FROZEN_ENV, "1")
    frozen = runner._cache_key(public)
    assert frozen == runner._cache_key(relabelled)
    # The pipeline marker (ROADMAP 3.8) does move the key.
    assert frozen != post_fix


def test_frozen_cache_key_is_the_key_from_before_data_access(monkeypatch):
    """With the pipeline frozen, the key is exactly the pre-``data_access`` formula (PR 122's guarantee)."""
    monkeypatch.setenv(runner.PIPELINE_FROZEN_ENV, "1")
    public = _entry(dataset=bschema.DatasetRef(source="https://zenodo.org/records/1"))
    payload = runner._entry_to_jsonable(public)
    payload["dataset"].pop("data_access")
    for k in ("split", "publication_date", "package_release_date"):
        payload.pop(k)
    expected = json.dumps(
        {
            "entry": payload,
            "retally_version": runner._retally_version(),
            "mode": runner.SEEDED,
            "model": runner.pipeline_model(),
        },
        sort_keys=True,
        default=str,
    )
    assert runner._cache_key(public) == hashlib.sha256(expected.encode("utf-8")).hexdigest()[:16]


# ── Strip + mount ───────────────────────────────────────────────────────


def _render(tmp_path, entry, mode, package_dir=None, run_id="r1"):
    return render_mod.render_task(
        entry,
        mode,
        run_id,
        task_root=tmp_path / "tasks",
        reproductions_dir=tmp_path / "reproductions",
        package_dir=package_dir,
        paper_text="Warfare and development. beta is reported in Table 1.",
    )


def _mounted(rendered) -> set[str]:
    return {
        p.relative_to(rendered.mount_path).as_posix() for p in rendered.mount_path.rglob("*") if p.is_file()
    }


@pytest.mark.parametrize("mode", ["seeded", "independent", "blind"])
def test_manual_zip_goes_through_strip_and_mount_like_a_zenodo_package(tmp_path, monkeypatch, mode):
    monkeypatch.chdir(tmp_path)  # the downloader's default cache (.cache/datasets) lands here
    placed = _zip_package(tmp_path / "manual-packages" / "T73" / "149882-V1.zip")
    manual = _render(tmp_path / "m", _entry(dataset=_manual(str(placed))), mode)
    zenodo = _render(
        tmp_path / "z",
        _entry(dataset=bschema.DatasetRef(source="https://zenodo.org/records/1")),
        mode,
        package_dir=PACKAGE_DIR,
    )
    # Same files mounted and the same files withheld.  The manual mount adds its provenance and
    # the download sentinel, which a real Zenodo download carries too (the fixture is a bare dir).
    assert _mounted(manual) == _mounted(zenodo) | {"metadata.json", _COMPLETE_SENTINEL}
    assert manual.render["n_files_stripped"] == zenodo.render["n_files_stripped"]
    if mode == "seeded":
        assert "code/master.do" in _mounted(manual)
    else:
        assert manual.render["n_files_stripped"] == 2
        assert strip_rule.classify_tree(manual.mount_path) == []
    meta = json.loads((manual.mount_path / "metadata.json").read_text(encoding="utf-8"))
    assert (
        meta["data_access"] == "manual" and meta["sha256"] == hashlib.sha256(placed.read_bytes()).hexdigest()
    )
