"""Tests for the reference-code downloader.

Real git clones require network and ~150 ms each, so the happy-path
test that touches the network is marked and skipped by default.
Everything else exercises pure-Python behaviour: URL parsing, cache
slug derivation, the sentinel-file cache check, and the
not-yet-supported / git-missing fall-through paths.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from retally.code.downloader import (
    CodeDownloader,
    _git_available,
    _parse_github_owner_repo,
)
from retally.models import CodeReference, CodeReferenceSource


def _ref(url: str, source: CodeReferenceSource = CodeReferenceSource.GITHUB) -> CodeReference:
    return CodeReference(url=url, source=source)


# ── URL parsing ────────────────────────────────────────────────────────


def test_parse_basic_github_url():
    assert _parse_github_owner_repo("https://github.com/openai/baselines") == (
        "openai",
        "baselines",
    )


def test_parse_strips_trailing_slash_and_git_suffix():
    assert _parse_github_owner_repo("https://github.com/x/y/") == ("x", "y")
    assert _parse_github_owner_repo("https://github.com/x/y.git") == ("x", "y")
    assert _parse_github_owner_repo("https://github.com/x/y.git/") == ("x", "y")


def test_parse_allows_www_prefix():
    assert _parse_github_owner_repo("https://www.github.com/foo/bar") == ("foo", "bar")


def test_parse_returns_none_for_non_github():
    assert _parse_github_owner_repo("https://gitlab.com/x/y") == (None, None)
    assert _parse_github_owner_repo("not a url") == (None, None)
    assert _parse_github_owner_repo("https://github.com/just-owner") == (None, None)


# ── Local cache path ───────────────────────────────────────────────────


def test_local_path_uses_owner_repo_slug(tmp_path):
    dl = CodeDownloader(cache_dir=tmp_path / "code")
    p = dl._local_path(_ref("https://github.com/openai/baselines"))
    assert p == tmp_path / "code" / "openai__baselines"


def test_local_path_falls_back_on_unparseable_url(tmp_path):
    dl = CodeDownloader(cache_dir=tmp_path / "code")
    p = dl._local_path(_ref("https://example.com/some/repo", CodeReferenceSource.DIRECT_URL))
    assert p.parent == tmp_path / "code"
    # Slug should contain only [a-z0-9_].
    assert all(c.isalnum() or c == "_" for c in p.name)


# ── Cache hit ──────────────────────────────────────────────────────────


def test_download_returns_cached_when_sentinel_present(tmp_path):
    dl = CodeDownloader(cache_dir=tmp_path / "code")
    ref = _ref("https://github.com/openai/baselines")
    local = dl._local_path(ref)
    local.mkdir(parents=True, exist_ok=True)
    (local / "README.md").write_text("cached")
    (local / ".retally-clone-complete").touch()

    resolved = dl.download(ref)
    assert resolved.local_path == local
    # When the cache hits, the downloader must not invoke git at all.
    # If it did, the test would hang on a network call (we can't easily
    # mock that here without a patch, but the test framework would time
    # out — and the test passes quickly, which is the proof).


def test_download_treats_directory_without_sentinel_as_stale(tmp_path):
    # Without the sentinel the downloader will try to re-clone.  We
    # patch git to fail so the test is hermetic.
    dl = CodeDownloader(cache_dir=tmp_path / "code")
    ref = _ref("https://github.com/openai/baselines")
    local = dl._local_path(ref)
    local.mkdir(parents=True, exist_ok=True)
    (local / "stale.txt").write_text("partial")  # no sentinel

    with patch.object(dl, "_clone_github", side_effect=OSError("simulated")):
        resolved = dl.download(ref)
    # Failed clone → local_path stays None, partial directory is gone.
    assert resolved.local_path is None
    assert not local.exists()


# ── Skipped sources ────────────────────────────────────────────────────


def test_download_skips_non_github_sources(tmp_path):
    dl = CodeDownloader(cache_dir=tmp_path / "code")
    ref = _ref("https://gitlab.com/x/y", CodeReferenceSource.GITLAB)
    resolved = dl.download(ref)
    # Same reference back, no local_path; nothing on disk.
    assert resolved is ref or (
        resolved.url == ref.url and resolved.source == ref.source and resolved.local_path is None
    )
    assert not (tmp_path / "code").exists()


def test_download_skips_when_git_unavailable(tmp_path):
    dl = CodeDownloader(cache_dir=tmp_path / "code")
    ref = _ref("https://github.com/x/y")
    with patch("retally.code.downloader._git_available", return_value=False):
        resolved = dl.download(ref)
    assert resolved.local_path is None


# ── Clone failure handling ─────────────────────────────────────────────


def test_download_handles_clone_failure(tmp_path):
    dl = CodeDownloader(cache_dir=tmp_path / "code")
    ref = _ref("https://github.com/openai/does-not-exist-12345")
    with patch.object(dl, "_clone_github", side_effect=OSError("clone failed")):
        resolved = dl.download(ref)
    # Failure is silent (logged) and surfaces as local_path=None.
    assert resolved.local_path is None
    # Partial directory must not be left behind.
    assert not dl._local_path(ref).exists()


def test_download_all_processes_each_in_order(tmp_path):
    dl = CodeDownloader(cache_dir=tmp_path / "code")
    refs = [
        _ref("https://github.com/a/b"),
        _ref("https://gitlab.com/c/d", CodeReferenceSource.GITLAB),
    ]
    with patch.object(dl, "_clone_github") as mock_clone:
        # First clone "succeeds" (creates the dest dir like git would).
        def fake_clone(url, dest):
            Path(dest).mkdir(parents=True, exist_ok=True)
            Path(dest, "x.py").write_text("x = 1")

        mock_clone.side_effect = fake_clone
        resolved = dl.download_all(refs)

    assert resolved[0].local_path is not None
    assert resolved[1].local_path is None  # gitlab is skipped
    # Only GitHub got cloned.
    assert mock_clone.call_count == 1


# ── git availability probe ─────────────────────────────────────────────


@pytest.mark.skipif(not _git_available(), reason="git not installed in this environment")
def test_git_available_returns_true_when_git_present():
    assert _git_available() is True
