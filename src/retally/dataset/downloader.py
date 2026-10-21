"""
DatasetDownloader — retrieves datasets from various public repositories and
stores them locally.

Each public source has its own download strategy.  The main ``download``
method dispatches to the appropriate private helper based on
``DatasetReference.source``.

Supported sources:
  - Direct URL          (HTTP/HTTPS, with redirect handling)
  - Kaggle              (requires ~/.kaggle/kaggle.json credentials)
  - Zenodo              (REST API, no auth needed for public datasets)
  - UCI ML Repository   (ucimlrepo package)
  - Harvard Dataverse   (REST API)
  - FigShare            (REST API)
  - OpenML              (openml Python package)

Harvard Dataverse originals: Dataverse ingests tabular uploads (``.csv``,
``.dta``, ``.sav``, ...) and serves them as ``.tab`` by default, which breaks
replication scripts that read the files by their uploaded names.  For a file
whose metadata lists an ``originalFileFormat`` / ``originalFileName`` the
downloader requests ``/api/access/datafile/<id>?format=original`` and saves it
under the label stem with the original extension (``data.tab`` ->
``data.csv``); if the original request fails it falls back to the converted
``.tab`` and logs a warning.  Non-ingested files (``.tgz``, ``.R``, ``.dat``,
...) have no original format and are fetched as-is.
"""

from __future__ import annotations

import json
import logging
import re
import tarfile
import zipfile
from pathlib import Path
from typing import Any

import pandas as pd
import requests
from tqdm import tqdm

from retally.http_retry import get_with_retries, http_get, http_head, with_retries
from retally.models import Dataset, DatasetReference, DatasetSource

logger = logging.getLogger(__name__)

# Sentinel file written at the end of a successful download.  Its presence
# is the cache-validity signal; a partial/interrupted download leaves the
# directory without it and will be re-downloaded next time.
_COMPLETE_SENTINEL = ".retally-download-complete"

_ARCHIVE_SUFFIXES = (".zip", ".tar.gz", ".tgz", ".tar")

# MIME type -> extension for Dataverse ingested files whose metadata gives an
# ``originalFileFormat`` but no ``originalFileName``.
_ORIGINAL_FORMAT_EXTENSIONS = {
    "text/csv": ".csv",
    "text/comma-separated-values": ".csv",
    "text/tsv": ".tsv",
    "text/tab-separated-values": ".tsv",
    "application/x-stata": ".dta",
    "application/x-stata-13": ".dta",
    "application/x-stata-14": ".dta",
    "application/x-stata-15": ".dta",
    "application/x-spss-sav": ".sav",
    "application/x-spss-por": ".por",
    "application/x-rlang-transport": ".RData",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": ".xlsx",
}


def _infer_task_type(target: Any) -> str:
    """Return ``"classification"`` if the target has <=20 unique values, else ``"regression"``.

    Falls back to ``"classification"`` if ``nunique`` is unavailable on the
    given object (e.g. a non-DataFrame target).
    """
    try:
        nunique = target.nunique()
        # pandas DataFrames return a Series here; take the max so a multi-
        # column target counts as classification only when EVERY column is
        # low-cardinality.
        if hasattr(nunique, "max"):
            nunique = nunique.max()
        return "classification" if int(nunique) <= 20 else "regression"
    except (AttributeError, TypeError, ValueError):
        return "classification"


class DatasetDownloader:
    """Downloads datasets from public repositories to a local directory.

    Parameters
    ----------
    cache_dir:
        Root directory under which datasets are stored.  Each dataset gets
        its own subdirectory named after a slug of the dataset name.
    """

    def __init__(self, cache_dir: Path = Path(".cache/datasets")) -> None:
        self.cache_dir = Path(cache_dir)

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def download(self, reference: DatasetReference) -> Dataset:
        """Download the dataset described by ``reference`` and return a Dataset.

        Dispatches to the appropriate private method based on
        ``reference.source``.  A successful download is marked with a
        ``.retally-download-complete`` sentinel file in the destination
        directory; if that sentinel is present the cached result is
        returned without touching the network.  A partial / interrupted
        download leaves the sentinel absent and will be retried.

        Raises
        ------
        ValueError
            If ``reference.source`` is ``DatasetSource.UNKNOWN`` and no
            ``reference.url`` is provided.
        RuntimeError
            If the download fails.
        """
        dest = self._local_path(reference)

        # Return cached result only if the sentinel file is present.
        if (dest / _COMPLETE_SENTINEL).exists():
            return Dataset(
                name=reference.name,
                source_url=reference.url or "",
                local_path=dest,
                file_format="csv",
                metadata=self._read_metadata(dest),
            )

        dest.mkdir(parents=True, exist_ok=True)

        source = reference.source
        url = reference.url or ""

        try:
            if source == DatasetSource.UCI:
                self._download_uci(url, dest)
            elif source == DatasetSource.OPENML:
                self._download_openml(url, dest)
            elif source == DatasetSource.KAGGLE:
                self._download_kaggle(url, dest)
            elif source == DatasetSource.ZENODO:
                self._download_zenodo(url, dest)
            elif source == DatasetSource.HARVARD_DATAVERSE:
                self._download_harvard_dataverse(url, dest)
            elif source == DatasetSource.FIGSHARE:
                self._download_figshare(url, dest)
            elif source == DatasetSource.DIRECT_URL:
                if not url:
                    raise ValueError(
                        f"DatasetReference '{reference.name}' has source=DIRECT_URL but no url was provided."
                    )
                self._download_direct_url(url, dest)
            elif source == DatasetSource.UNKNOWN:
                if url:
                    self._download_direct_url(url, dest)
                else:
                    raise ValueError(
                        f"DatasetReference '{reference.name}' has source=UNKNOWN and no url. Cannot download."
                    )
            else:
                raise ValueError(f"Unsupported DatasetSource: {source}")
        except Exception as exc:
            raise RuntimeError(f"Failed to download dataset '{reference.name}': {exc}") from exc

        # Mark the cache as complete only after the dispatch returns
        # without raising.
        (dest / _COMPLETE_SENTINEL).touch()

        return Dataset(
            name=reference.name,
            source_url=url,
            local_path=dest,
            file_format="csv",
            metadata=self._read_metadata(dest),
        )

    def _read_metadata(self, dest: Path) -> dict[str, Any]:
        """Read ``metadata.json`` from ``dest`` if present, else return ``{}``."""
        meta_file = dest / "metadata.json"
        if not meta_file.exists():
            return {}
        try:
            with open(meta_file, "r", encoding="utf-8") as fh:
                return json.load(fh)
        except (json.JSONDecodeError, OSError) as exc:
            logger.warning("Could not parse metadata.json in %s: %s", dest, exc)
            return {}

    def _local_path(self, reference: DatasetReference) -> Path:
        """Return the local cache directory for this reference.

        Use a filesystem-safe slug of ``reference.name`` as the directory name
        (lowercase, spaces and slashes replaced with underscores).
        """
        slug = re.sub(r"[^a-z0-9]+", "_", reference.name.lower()).strip("_")
        return self.cache_dir / slug

    # ------------------------------------------------------------------
    # Private download helpers
    # ------------------------------------------------------------------

    def _download_uci(self, dataset_id: str, dest: Path) -> Path:
        """Download a dataset from the UCI ML Repository using ucimlrepo.

        Parameters
        ----------
        dataset_id:
            String representation of the UCI integer dataset id.
        dest:
            Destination directory.
        """
        try:
            from ucimlrepo import fetch_ucirepo  # type: ignore[import]
        except ImportError as exc:
            raise RuntimeError(
                "ucimlrepo is required to download UCI datasets. Install it with: pip install ucimlrepo"
            ) from exc

        try:
            ds = fetch_ucirepo(id=int(dataset_id))
            X: pd.DataFrame = ds.data.features
            y: pd.DataFrame = ds.data.targets
            df = pd.concat([X, y], axis=1)
        except Exception as exc:
            raise RuntimeError(f"Failed to fetch UCI dataset id={dataset_id}: {exc}") from exc

        dest.mkdir(parents=True, exist_ok=True)
        csv_path = dest / "data.csv"
        df.to_csv(csv_path, index=False)

        source_url = f"https://archive.ics.uci.edu/dataset/{dataset_id}"
        self._write_metadata(dest, df, source_url=source_url, task_type=_infer_task_type(y))
        return dest

    def _stream_to_file(
        self,
        url: str,
        dest: Path,
        filename: str,
        timeout: int = 120,
        extract_archives: bool = True,
    ) -> Path:
        """Stream ``url`` to ``dest/filename`` with a tqdm progress bar.

        If ``extract_archives`` is True and the file is a recognised archive
        (zip/tar/tar.gz/tgz), extract it into ``dest`` and delete the archive.

        Returns the path to the downloaded file (or to ``dest`` if extracted).
        Transient failures (connection drops, 5xx) are retried via
        ``retally.http_retry``; raises ``requests.RequestException`` once
        retries are exhausted or on a 4xx.
        """
        file_path = dest / filename

        def _fetch() -> None:
            # GET and body read retry together: a dropped connection
            # mid-zip surfaces as ChunkedEncodingError while iterating.
            # Each attempt rewrites the file from scratch ("wb").
            response = http_get(url, stream=True, timeout=timeout, allow_redirects=True)
            response.raise_for_status()
            total = int(response.headers.get("Content-Length", 0)) or None
            with (
                open(file_path, "wb") as fh,
                tqdm(desc=filename, total=total, unit="B", unit_scale=True, unit_divisor=1024) as pbar,
            ):
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        fh.write(chunk)
                        pbar.update(len(chunk))

        with_retries(_fetch, what=f"GET {url}")

        if extract_archives and filename.lower().endswith(_ARCHIVE_SUFFIXES):
            self._extract_archive(file_path, dest)
            return dest
        return file_path

    def _stream_many(self, file_specs: list[tuple[str, str]], dest: Path, source_label: str) -> int:
        """Stream each ``(url, filename)`` in ``file_specs`` into ``dest``.

        Per-file failures are logged and counted but do not abort the loop.
        Returns the number of files that failed; callers can record it in
        the dataset's metadata so partial completion is observable.
        """
        failures = 0
        for url, filename in file_specs:
            try:
                self._stream_to_file(url, dest, filename)
            except (requests.RequestException, OSError) as exc:
                failures += 1
                logger.warning("%s: failed to download %s (%s)", source_label, filename, exc)
        return failures

    def _download_direct_url(self, url: str, dest: Path) -> Path:
        """Download a single file from a direct HTTP/HTTPS URL.

        If the downloaded file is a zip/tar archive it is extracted into
        ``dest`` and the archive deleted.
        """
        dest.mkdir(parents=True, exist_ok=True)

        try:
            # HEAD the URL with redirects so we can extract the filename from
            # the Content-Disposition header without buffering the body.
            response = http_head(url, allow_redirects=True, timeout=30)
            response.raise_for_status()
            content_disposition = response.headers.get("Content-Disposition", "")
            final_url = response.url
        except requests.RequestException:
            # HEAD failed; fall back to the URL itself for filename inference.
            content_disposition = ""
            final_url = url

        if "filename=" in content_disposition:
            filename = content_disposition.split("filename=")[-1].strip().strip('"')
        else:
            filename = final_url.split("?")[0].rstrip("/").split("/")[-1] or "download"

        try:
            self._stream_to_file(url, dest, filename)
        except requests.RequestException as exc:
            raise RuntimeError(f"HTTP request failed for {url}: {exc}") from exc
        return dest

    def _download_kaggle(self, slug: str, dest: Path) -> Path:
        """Download a Kaggle dataset by its slug (e.g. 'username/dataset-name').

        Uses the ``kaggle`` CLI package.  Raises ``RuntimeError`` with a
        helpful message if Kaggle credentials are not configured.

        Parameters
        ----------
        slug:
            Kaggle dataset slug in the form ``owner/dataset-name``.
        dest:
            Destination directory.
        """
        try:
            import kaggle  # type: ignore[import]
        except ImportError as exc:
            raise RuntimeError("The kaggle package is required. Install it with: pip install kaggle") from exc

        dest.mkdir(parents=True, exist_ok=True)

        try:
            kaggle.api.authenticate()
        except Exception as exc:
            raise RuntimeError(
                "Kaggle authentication failed. Make sure ~/.kaggle/kaggle.json exists "
                "with your API credentials. See https://www.kaggle.com/docs/api for "
                f"instructions. Original error: {exc}"
            ) from exc

        try:
            kaggle.api.dataset_download_files(slug, path=str(dest), unzip=True)
        except Exception as exc:
            raise RuntimeError(f"Failed to download Kaggle dataset '{slug}': {exc}") from exc

        return dest

    def _download_zenodo(self, record_id_or_doi: str, dest: Path) -> Path:
        """Download all files from a Zenodo record.

        Strips the DOI prefix ``10.5281/zenodo.`` to get the numeric record ID
        if a DOI is supplied, then hits the Zenodo REST API to enumerate and
        download all files.

        Parameters
        ----------
        record_id_or_doi:
            Zenodo record id (numeric string) or full DOI string.
        dest:
            Destination directory.
        """
        # Accept a bare record id, a DOI (``10.5281/zenodo.<id>``), or a
        # full record URL (``https://zenodo.org/records/<id>`` — the form the
        # LLM extractor and the benchmark catalog use).  Reduce all three to
        # the numeric record id.
        raw = record_id_or_doi.strip()
        url_match = re.search(r"zenodo\.org/(?:records?|api/records)/(\d+)", raw)
        if url_match:
            record_id = url_match.group(1)
        else:
            record_id = re.sub(r"^10\.5281/zenodo\.", "", raw)

        api_url = f"https://zenodo.org/api/records/{record_id}"
        try:
            response = get_with_retries(api_url, timeout=30)
            record = response.json()
        except requests.RequestException as exc:
            raise RuntimeError(f"Failed to fetch Zenodo record metadata for id={record_id}: {exc}") from exc

        files = record.get("files", [])
        if not files:
            raise RuntimeError(f"Zenodo record {record_id} has no files listed in the API response.")

        dest.mkdir(parents=True, exist_ok=True)

        file_specs: list[tuple[str, str]] = []
        for file_info in files:
            file_url = file_info.get("links", {}).get("self") or file_info.get("download_url")
            if not file_url:
                continue
            filename = file_info.get("filename") or file_info.get("key") or file_url.split("/")[-1]
            file_specs.append((file_url, filename))

        failures = self._stream_many(file_specs, dest, source_label=f"Zenodo {record_id}")
        if failures and failures == len(file_specs):
            raise RuntimeError(f"All {failures} files from Zenodo record {record_id} failed to download.")
        return dest

    def _download_openml(self, dataset_id: str, dest: Path) -> Path:
        """Download a dataset from OpenML.

        Uses the ``openml`` Python package.  Raises ``RuntimeError`` with
        install instructions if openml is not available.

        Parameters
        ----------
        dataset_id:
            String representation of the OpenML dataset id.
        dest:
            Destination directory.
        """
        try:
            import openml  # type: ignore[import]
        except ImportError as exc:
            raise RuntimeError(
                "openml is required to download OpenML datasets. Install it with: pip install openml"
            ) from exc

        try:
            ds = openml.datasets.get_dataset(int(dataset_id))
            X, y, _, _ = ds.get_data(target=ds.default_target_attribute)
        except Exception as exc:
            raise RuntimeError(f"Failed to fetch OpenML dataset id={dataset_id}: {exc}") from exc

        # Build a combined DataFrame
        if isinstance(X, pd.DataFrame):
            df = X.copy()
        else:
            df = pd.DataFrame(X)

        if y is not None:
            target_name = ds.default_target_attribute or "target"
            df[target_name] = y.values if hasattr(y, "values") else y

        dest.mkdir(parents=True, exist_ok=True)
        csv_path = dest / "data.csv"
        df.to_csv(csv_path, index=False)

        source_url = f"https://www.openml.org/d/{dataset_id}"
        self._write_metadata(dest, df, source_url=source_url, task_type=_infer_task_type(df.iloc[:, -1]))
        return dest

    @staticmethod
    def _dataverse_persistent_id(value: str) -> str:
        """Normalise a Dataverse reference to the ``doi:...`` persistentId form.

        Catalog entries name the dataset by its human-facing landing URL
        (``https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/XXXX``),
        but the API wants the bare persistent identifier.  Accept the landing
        URL, a ``https://doi.org/...`` link, a bare ``10.7910/...`` DOI, or an
        already-normalised ``doi:``/``hdl:`` id, and return the API form.
        """
        raw = value.strip()
        # Landing URL carrying an explicit ?persistentId=... parameter.
        param = re.search(r"[?&]persistentId=([^&]+)", raw)
        if param:
            return param.group(1)
        # Already a persistent id.
        if raw.startswith(("doi:", "hdl:")):
            return raw
        # doi.org URL or bare DOI -> doi: form.
        doi = re.search(r"(10\.\d{4,}/[^\s?&]+)", raw)
        if doi:
            return f"doi:{doi.group(1)}"
        return raw

    @staticmethod
    def _dataverse_original_name(data_file: dict[str, Any]) -> str | None:
        """Return the filename to save an ingested Dataverse file's original under.

        Dataverse ingests tabular uploads (``.csv``, ``.dta``, ``.sav``, ...)
        and serves them as ``<label>.tab`` by default; the upload itself is
        only served with ``?format=original``.  A file that was not ingested
        (no ``originalFileFormat`` / ``originalFileName``) returns ``None``
        and is fetched as-is.

        The name is the file's current label with the original extension
        (``data.tab`` + ``data.csv`` -> ``data.csv``): the label is what the
        dataset page shows and what replication scripts are written
        against, whereas ``originalFileName`` can carry an upload-time
        artefact (arias-2022 lists ``usclimate_exp1.tab`` with original name
        ``usclimate_exp1-1.csv``, and the script reads ``usclimate_exp1.csv``).
        ``originalFileName`` is used as-is when the label is not a ``.tab``
        or the original name has no extension.
        """
        original_name = data_file.get("originalFileName")
        if not data_file.get("originalFileFormat") and not original_name:
            return None
        label = str(data_file.get("filename") or "")
        if original_name:
            suffix = Path(str(original_name)).suffix
            if suffix and label.lower().endswith(".tab"):
                return Path(label).stem + suffix
            return Path(str(original_name)).name
        # Ingested but the original name is missing: infer the extension.
        ext = _ORIGINAL_FORMAT_EXTENSIONS.get(str(data_file.get("originalFileFormat")))
        if ext and label.lower().endswith(".tab"):
            return Path(label).stem + ext
        return None

    def _download_harvard_dataverse(self, doi: str, dest: Path) -> Path:
        """Download a dataset from Harvard Dataverse.

        Uses the Dataverse REST API to list files, then downloads each one
        in a deterministic (name-sorted) order.  Ingested tabular files are
        fetched in their original upload format (``?format=original``, see
        ``_dataverse_original_name``); if that request fails the converted
        ``.tab`` is downloaded instead and the fallback is logged.  Files
        that were not ingested (archives such as ``.tgz``, scripts, ``.dat``)
        are fetched as-is, and archives are extracted as usual.

        Parameters
        ----------
        doi:
            Persistent identifier (DOI) for the Dataverse dataset, or a
            landing-page URL / ``doi.org`` link that carries one.
        dest:
            Destination directory.
        """
        doi = self._dataverse_persistent_id(doi)
        api_url = f"https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId={doi}"
        try:
            response = get_with_retries(api_url, timeout=30)
            data = response.json()
        except requests.RequestException as exc:
            raise RuntimeError(f"Failed to fetch Harvard Dataverse metadata for doi={doi}: {exc}") from exc

        try:
            files = data["data"]["latestVersion"]["files"]
        except (KeyError, TypeError) as exc:
            raise RuntimeError(f"Unexpected Harvard Dataverse API response structure: {exc}") from exc

        dest.mkdir(parents=True, exist_ok=True)

        # (converted_url, converted_name, original_url | None, original_name | None)
        specs: list[tuple[str, str, str | None, str | None]] = []
        for file_info in files:
            try:
                data_file = file_info["dataFile"]
                file_id = data_file["id"]
                filename = data_file["filename"]
            except (KeyError, TypeError):
                logger.warning("Harvard Dataverse %s: skipping file with malformed metadata", doi)
                continue
            file_url = f"https://dataverse.harvard.edu/api/access/datafile/{file_id}"
            original_name = self._dataverse_original_name(data_file)
            original_url = f"{file_url}?format=original" if original_name else None
            specs.append((file_url, filename, original_url, original_name))
        # Deterministic order regardless of how the API lists the files.
        specs.sort(key=lambda spec: (spec[3] or spec[1], spec[1]))

        label = f"Harvard Dataverse {doi}"
        failures = 0
        for file_url, filename, original_url, original_name in specs:
            if original_url and original_name:
                try:
                    self._stream_to_file(original_url, dest, original_name)
                    continue
                except (requests.RequestException, OSError) as exc:
                    (dest / original_name).unlink(missing_ok=True)
                    logger.warning(
                        "%s: original-format download of %s failed (%s); falling back to the converted %s",
                        label,
                        original_name,
                        exc,
                        filename,
                    )
            try:
                self._stream_to_file(file_url, dest, filename)
            except (requests.RequestException, OSError) as exc:
                failures += 1
                logger.warning("%s: failed to download %s (%s)", label, filename, exc)

        if failures and failures == len(specs):
            raise RuntimeError(f"All {failures} files from Harvard Dataverse {doi} failed to download.")
        return dest

    def _download_figshare(self, article_id: str, dest: Path) -> Path:
        """Download files from a FigShare article.

        Uses the FigShare public API to list files, then downloads each one.

        Parameters
        ----------
        article_id:
            FigShare article id (numeric string).
        dest:
            Destination directory.
        """
        api_url = f"https://api.figshare.com/v2/articles/{article_id}/files"
        try:
            response = get_with_retries(api_url, timeout=30)
            files = response.json()
        except requests.RequestException as exc:
            raise RuntimeError(f"Failed to fetch FigShare article files for id={article_id}: {exc}") from exc

        if not isinstance(files, list) or not files:
            raise RuntimeError(f"FigShare article {article_id} has no downloadable files.")

        dest.mkdir(parents=True, exist_ok=True)

        file_specs: list[tuple[str, str]] = []
        for file_info in files:
            file_url = file_info.get("download_url")
            if not file_url:
                logger.warning("FigShare %s: skipping file without download_url", article_id)
                continue
            filename = file_info.get("name") or file_url.split("/")[-1]
            file_specs.append((file_url, filename))

        failures = self._stream_many(file_specs, dest, source_label=f"FigShare {article_id}")
        if failures and failures == len(file_specs):
            raise RuntimeError(f"All {failures} files from FigShare article {article_id} failed to download.")
        return dest

    def _extract_archive(self, archive_path: Path, dest: Path) -> Path:
        """Extract a zip or tar archive into ``dest`` and delete the archive."""
        name_lower = archive_path.name.lower()
        try:
            if name_lower.endswith(".zip"):
                with zipfile.ZipFile(archive_path, "r") as zf:
                    zf.extractall(dest)
            elif name_lower.endswith((".tar.gz", ".tgz", ".tar")):
                with tarfile.open(archive_path, "r:*") as tf:
                    tf.extractall(dest)
            else:
                logger.warning("Unrecognised archive format for %s, leaving as-is.", archive_path.name)
                return dest
        except (zipfile.BadZipFile, tarfile.TarError, OSError) as exc:
            logger.warning("Could not extract %s: %s", archive_path.name, exc)
            return dest

        try:
            archive_path.unlink()
        except OSError as exc:
            logger.warning("Could not delete archive %s: %s", archive_path, exc)

        return dest

    # ------------------------------------------------------------------
    # Metadata helper
    # ------------------------------------------------------------------

    def _write_metadata(
        self,
        dest: Path,
        df: pd.DataFrame,
        source_url: str,
        task_type: str = "classification",
    ) -> None:
        """Write a metadata.json sidecar file alongside the CSV.

        Parameters
        ----------
        dest:
            Directory containing data.csv (metadata.json is written here).
        df:
            The combined DataFrame (features + target).
        source_url:
            Original download URL or API URL for provenance tracking.
        task_type:
            ``"classification"`` or ``"regression"``.
        """
        target_column = df.columns[-1] if len(df.columns) > 0 else None
        metadata: dict[str, Any] = {
            "columns": list(df.columns),
            "target_column": target_column,
            "n_rows": int(len(df)),
            "n_cols": int(len(df.columns)),
            "task_type": task_type,
            "file_format": "csv",
            "source_url": source_url,
        }
        meta_path = dest / "metadata.json"
        with open(meta_path, "w", encoding="utf-8") as fh:
            json.dump(metadata, fh, indent=2)
