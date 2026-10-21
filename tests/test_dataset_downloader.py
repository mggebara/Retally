"""Tests for DatasetDownloader and DatasetRegistry."""

import json
from unittest.mock import MagicMock, patch

import pytest
import requests

from retally.dataset.downloader import DatasetDownloader
from retally.dataset.registry import DatasetRegistry
from retally.models import DatasetReference, DatasetSource


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


def test_download_returns_cached_if_complete_sentinel_present(downloader, tmp_path):
    ref = DatasetReference(name="test-ds", source=DatasetSource.DIRECT_URL, url="http://example.com/ds.csv")
    local = downloader._local_path(ref)
    local.mkdir(parents=True, exist_ok=True)
    (local / "data.csv").write_text("a,b\n1,2\n")
    # The sentinel file is the cache-validity signal; without it the
    # downloader treats the directory as a partial / interrupted download
    # and re-fetches.
    (local / ".retally-download-complete").touch()
    dataset = downloader.download(ref)
    assert dataset.local_path == local


def test_download_ignores_cache_without_sentinel(downloader, tmp_path):
    # A directory with data files but no .retally-download-complete sentinel
    # represents a partial download.  It must NOT be returned as cached;
    # the download is retried (and here fails because the URL is fake).
    ref = DatasetReference(
        name="partial-ds", source=DatasetSource.DIRECT_URL, url="http://example.com/ds.csv"
    )
    local = downloader._local_path(ref)
    local.mkdir(parents=True, exist_ok=True)
    (local / "data.csv").write_text("a,b\n1,2\n")  # partial
    with pytest.raises(RuntimeError, match="Failed to download"):
        downloader.download(ref)


def test_download_loads_metadata_from_sidecar(downloader, tmp_path):
    ref = DatasetReference(name="cached-ds", source=DatasetSource.DIRECT_URL, url="")
    local = downloader._local_path(ref)
    local.mkdir(parents=True, exist_ok=True)
    (local / "data.csv").write_text("a,b\n1,2\n")
    meta = {
        "columns": ["a", "b"],
        "target_column": "b",
        "n_rows": 1,
        "n_cols": 2,
        "task_type": "classification",
        "file_format": "csv",
        "source_url": "",
    }
    (local / "metadata.json").write_text(json.dumps(meta))
    (local / ".retally-download-complete").touch()
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
    ref = DatasetReference(
        name="My Custom Dataset", source=DatasetSource.DIRECT_URL, url="http://example.com/data.csv"
    )
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


@pytest.mark.parametrize(
    "value,expected",
    [
        ("doi:10.7910/DVN/S5YMS7", "doi:10.7910/DVN/S5YMS7"),
        (
            "https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/FDML2N",
            "doi:10.7910/DVN/FDML2N",
        ),
        ("https://doi.org/10.7910/DVN/NGFLRO", "doi:10.7910/DVN/NGFLRO"),
        ("10.7910/DVN/NGFLRO", "doi:10.7910/DVN/NGFLRO"),
        ("hdl:1902.1/12345", "hdl:1902.1/12345"),
    ],
)
def test_dataverse_persistent_id_normalisation(value, expected):
    assert DatasetDownloader._dataverse_persistent_id(value) == expected


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


# --- Harvard Dataverse: ingested files are fetched in their original format ---


_DV_BASE = "https://dataverse.harvard.edu/api/access/datafile/"


def _dv_response(url, body=b"", status=200, json_body=None):
    resp = MagicMock()
    resp.status_code = status
    resp.url = url
    resp.headers = {}
    if status >= 400:
        resp.raise_for_status.side_effect = requests.HTTPError(f"{status} for {url}", response=resp)
    else:
        resp.raise_for_status.return_value = None
    resp.json.return_value = json_body
    resp.iter_content.side_effect = lambda chunk_size=8192: iter([body])
    return resp


def _dv_files():
    return [
        # Listed out of name order so the test also checks the sort.
        {
            "dataFile": {
                "id": 1,
                "filename": "survey.tab",
                "contentType": "text/tab-separated-values",
                "originalFileFormat": "text/csv",
                "originalFileName": "survey-1.csv",
            }
        },
        {"dataFile": {"id": 2, "filename": "conjoint_design.dat", "contentType": "text/x-fixed-field"}},
    ]


def _run_dataverse(tmp_path, routes):
    """Run the Dataverse download with ``requests.get`` routed by URL; return dest and URLs requested."""
    requested: list[str] = []

    def fake_get(url, **kwargs):
        requested.append(url)
        if "/api/datasets/" in url:
            metadata = {"status": "OK", "data": {"latestVersion": {"files": _dv_files()}}}
            return _dv_response(url, json_body=metadata)
        status, body = routes[url]
        return _dv_response(url, body=body, status=status)

    dest = tmp_path / "pkg"
    with patch("requests.get", side_effect=fake_get), patch("retally.http_retry.time.sleep"):
        DatasetDownloader(cache_dir=tmp_path)._download_harvard_dataverse("doi:10.7910/DVN/TEST01", dest)
    return dest, requested


def test_dataverse_fetches_ingested_file_in_original_format(tmp_path):
    routes = {
        f"{_DV_BASE}1?format=original": (200, b"a,b\n1,2\n"),
        f"{_DV_BASE}2": (200, b"fixed field"),
    }
    dest, requested = _run_dataverse(tmp_path, routes)

    # Label stem + original extension; the converted .tab is never requested.
    assert (dest / "survey.csv").read_bytes() == b"a,b\n1,2\n"
    assert not (dest / "survey.tab").exists()
    assert (dest / "conjoint_design.dat").read_bytes() == b"fixed field"
    # Plain file fetched as-is (no ?format=original); deterministic name order.
    assert requested[1:] == [f"{_DV_BASE}2", f"{_DV_BASE}1?format=original"]


def test_dataverse_falls_back_to_converted_file_when_original_fails(tmp_path, caplog):
    routes = {
        f"{_DV_BASE}1?format=original": (404, b""),
        f"{_DV_BASE}1": (200, b"a\tb\n1\t2\n"),
        f"{_DV_BASE}2": (200, b"fixed field"),
    }
    with caplog.at_level("WARNING"):
        dest, _ = _run_dataverse(tmp_path, routes)

    assert (dest / "survey.tab").read_bytes() == b"a\tb\n1\t2\n"
    assert not (dest / "survey.csv").exists()
    assert "falling back to the converted survey.tab" in caplog.text


@pytest.mark.parametrize(
    "data_file, expected",
    [
        ({"filename": "x.R"}, None),
        ({"filename": "Replication.tgz", "contentType": "application/x-gzip"}, None),
        ({"filename": "a.tab", "originalFileFormat": "text/csv", "originalFileName": "a.csv"}, "a.csv"),
        ({"filename": "a.tab", "originalFileFormat": "text/csv", "originalFileName": "a-1.csv"}, "a.csv"),
        ({"filename": "d.tab", "originalFileFormat": "application/x-stata-14"}, "d.dta"),
        ({"filename": "renamed.txt", "originalFileName": "orig.sav"}, "orig.sav"),
    ],
)
def test_dataverse_original_name(data_file, expected):
    assert DatasetDownloader._dataverse_original_name(data_file) == expected
