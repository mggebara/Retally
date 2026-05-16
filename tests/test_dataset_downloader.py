"""Tests for DatasetDownloader."""

import pytest
from pathlib import Path
from unittest.mock import MagicMock, patch

from paper_validator.dataset.downloader import DatasetDownloader
from paper_validator.models import DatasetReference, DatasetSource


@pytest.fixture
def downloader(tmp_path):
    return DatasetDownloader(cache_dir=tmp_path / "datasets")


@pytest.mark.skip(reason="not implemented")
def test_local_path_slugifies_name(downloader):
    ref = DatasetReference(name="UCI Adult Income", source=DatasetSource.UCI)
    path = downloader._local_path(ref)
    assert "UCI Adult Income" not in str(path)
    assert " " not in str(path)


@pytest.mark.skip(reason="not implemented")
def test_download_returns_cached_if_exists(downloader, tmp_path):
    ref = DatasetReference(name="test-ds", source=DatasetSource.DIRECT_URL, url="http://example.com/ds.csv")
    local = downloader._local_path(ref)
    local.mkdir(parents=True, exist_ok=True)
    (local / "data.csv").write_text("a,b\n1,2\n")
    # Should return without making any network call
    dataset = downloader.download(ref)
    assert dataset.local_path == local


@pytest.mark.skip(reason="requires network")
def test_download_zenodo_record():
    downloader = DatasetDownloader()
    ref = DatasetReference(
        name="example-zenodo",
        source=DatasetSource.ZENODO,
        url="10.5281/zenodo.3490684",
    )
    dataset = downloader.download(ref)
    assert dataset.local_path.exists()
