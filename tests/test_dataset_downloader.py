"""Tests for DatasetDownloader and DatasetRegistry."""

import json
import pytest
from pathlib import Path
from unittest.mock import MagicMock, patch

from paper_validator.dataset.downloader import DatasetDownloader
from paper_validator.dataset.registry import DatasetRegistry
from paper_validator.models import DatasetReference, DatasetSource


@pytest.fixture
def downloader(tmp_path):
    return DatasetDownloader(cache_dir=tmp_path / "datasets")


@pytest.fixture
def registry(tmp_path):
    reg = DatasetRegistry(registry_path=tmp_path / "registry.json")
    reg.load()
    return reg


# --- DatasetDownloader tests ---

def test_local_path_slugifies_name(downloader):
    ref = DatasetReference(name="UCI Adult Income", source=DatasetSource.UCI)
    path = downloader._local_path(ref)
    assert "UCI Adult Income" not in str(path)
    assert " " not in str(path)


def test_local_path_uses_cache_dir(downloader, tmp_path):
    ref = DatasetReference(name="iris", source=DatasetSource.UCI)
    path = downloader._local_path(ref)
    assert str(tmp_path / "datasets") in str(path)


def test_download_returns_cached_if_exists(downloader, tmp_path):
    ref = DatasetReference(name="test-ds", source=DatasetSource.DIRECT_URL, url="http://example.com/ds.csv")
    local = downloader._local_path(ref)
    local.mkdir(parents=True, exist_ok=True)
    (local / "data.csv").write_text("a,b\n1,2\n")
    dataset = downloader.download(ref)
    assert dataset.local_path == local


def test_download_loads_metadata_from_sidecar(downloader, tmp_path):
    ref = DatasetReference(name="cached-ds", source=DatasetSource.DIRECT_URL, url="")
    local = downloader._local_path(ref)
    local.mkdir(parents=True, exist_ok=True)
    (local / "data.csv").write_text("a,b\n1,2\n")
    meta = {"columns": ["a", "b"], "target_column": "b", "n_rows": 1,
            "n_cols": 2, "task_type": "classification", "file_format": "csv", "source_url": ""}
    (local / "metadata.json").write_text(json.dumps(meta))
    dataset = downloader.download(ref)
    assert dataset.metadata["target_column"] == "b"


# --- DatasetRegistry tests ---

def test_registry_loads_builtins(registry):
    # At least the UCI classics should be pre-populated
    assert registry.lookup("iris") is not None
    assert registry.lookup("adult income") is not None
    assert registry.lookup("breast cancer wisconsin") is not None


def test_registry_lookup_case_insensitive(registry):
    assert registry.lookup("Iris") is not None
    assert registry.lookup("IRIS") is not None


def test_registry_lookup_returns_none_for_unknown(registry):
    assert registry.lookup("this dataset does not exist 12345") is None


def test_registry_register_and_lookup(registry):
    ref = DatasetReference(name="My Custom Dataset", source=DatasetSource.DIRECT_URL, url="http://example.com/data.csv")
    registry.register(ref)
    result = registry.lookup("my custom dataset")
    assert result is not None
    assert result.url == "http://example.com/data.csv"


def test_registry_search(registry):
    results = registry.search("classification")
    assert isinstance(results, list)


def test_registry_builtin_iris_has_uci_source(registry):
    ref = registry.lookup("iris")
    assert ref.source == DatasetSource.UCI


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
