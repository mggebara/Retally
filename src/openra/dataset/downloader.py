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
"""

from __future__ import annotations

import json
import re
import tarfile
import zipfile
from pathlib import Path
from typing import Any

import pandas as pd
import requests
from tqdm import tqdm

from openra.models import Dataset, DatasetReference, DatasetSource


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
        ``reference.source``.  If the dataset is already present in the
        cache (local_path exists and contains at least one .csv file),
        skip the download and return the cached Dataset immediately.

        Raises
        ------
        ValueError
            If ``reference.source`` is ``DatasetSource.UNKNOWN`` and no
            ``reference.url`` is provided.
        RuntimeError
            If the download fails after retries.
        """
        dest = self._local_path(reference)

        # Return cached result if a CSV is already present
        if dest.exists() and any(dest.glob("*.csv")):
            metadata: dict[str, Any] = {}
            meta_file = dest / "metadata.json"
            if meta_file.exists():
                try:
                    with open(meta_file, "r", encoding="utf-8") as fh:
                        metadata = json.load(fh)
                except (json.JSONDecodeError, OSError):
                    pass
            return Dataset(
                name=reference.name,
                source_url=reference.url or "",
                local_path=dest,
                file_format="csv",
                metadata=metadata,
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

        metadata = {}
        meta_file = dest / "metadata.json"
        if meta_file.exists():
            try:
                with open(meta_file, "r", encoding="utf-8") as fh:
                    metadata = json.load(fh)
            except (json.JSONDecodeError, OSError):
                pass

        return Dataset(
            name=reference.name,
            source_url=url,
            local_path=dest,
            file_format="csv",
            metadata=metadata,
        )

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

        # Determine task type heuristically
        try:
            max_unique = y.nunique().max()
            task_type = "classification" if max_unique <= 20 else "regression"
        except Exception:
            task_type = "classification"

        source_url = f"https://archive.ics.uci.edu/dataset/{dataset_id}"
        self._write_metadata(dest, df, source_url=source_url, task_type=task_type)
        return dest

    def _download_direct_url(self, url: str, dest: Path) -> Path:
        """Download a file from a direct HTTP/HTTPS URL.

        Uses ``requests.get`` with ``stream=True`` and writes in 8192-byte chunks.
        Shows a tqdm progress bar.  If the downloaded file is a zip or tar archive
        it will be extracted into ``dest``.

        Parameters
        ----------
        url:
            Remote URL to fetch.
        dest:
            Destination directory.
        """
        dest.mkdir(parents=True, exist_ok=True)

        try:
            response = requests.get(url, stream=True, timeout=60, allow_redirects=True)
            response.raise_for_status()
        except requests.RequestException as exc:
            raise RuntimeError(f"HTTP request failed for {url}: {exc}") from exc

        # Determine filename from URL or Content-Disposition header
        content_disposition = response.headers.get("Content-Disposition", "")
        if "filename=" in content_disposition:
            filename = content_disposition.split("filename=")[-1].strip().strip('"')
        else:
            filename = url.split("?")[0].rstrip("/").split("/")[-1] or "download"

        content_length = response.headers.get("Content-Length")
        total = int(content_length) if content_length and content_length.isdigit() else None

        file_path = dest / filename
        chunk_size = 8192

        with (
            open(file_path, "wb") as fh,
            tqdm(
                desc=filename,
                total=total,
                unit="B",
                unit_scale=True,
                unit_divisor=1024,
            ) as pbar,
        ):
            for chunk in response.iter_content(chunk_size=chunk_size):
                if chunk:
                    fh.write(chunk)
                    pbar.update(len(chunk))

        # Extract archive if needed
        name_lower = filename.lower()
        if (
            name_lower.endswith(".zip")
            or name_lower.endswith(".tar.gz")
            or name_lower.endswith(".tgz")
            or name_lower.endswith(".tar")
        ):
            self._extract_archive(file_path, dest)

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
        # Strip DOI prefix if present
        record_id = re.sub(r"^10\.5281/zenodo\.", "", record_id_or_doi.strip())

        api_url = f"https://zenodo.org/api/records/{record_id}"
        try:
            response = requests.get(api_url, timeout=30)
            response.raise_for_status()
            record = response.json()
        except requests.RequestException as exc:
            raise RuntimeError(f"Failed to fetch Zenodo record metadata for id={record_id}: {exc}") from exc

        files = record.get("files", [])
        if not files:
            raise RuntimeError(f"Zenodo record {record_id} has no files listed in the API response.")

        dest.mkdir(parents=True, exist_ok=True)

        for file_info in files:
            file_url = file_info.get("links", {}).get("self") or file_info.get("download_url")
            if not file_url:
                continue
            filename = file_info.get("filename") or file_info.get("key") or file_url.split("/")[-1]
            file_path = dest / filename
            try:
                r = requests.get(file_url, stream=True, timeout=120)
                r.raise_for_status()
                total = int(r.headers.get("Content-Length", 0)) or None
                with (
                    open(file_path, "wb") as fh,
                    tqdm(
                        desc=filename,
                        total=total,
                        unit="B",
                        unit_scale=True,
                        unit_divisor=1024,
                    ) as pbar,
                ):
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            fh.write(chunk)
                            pbar.update(len(chunk))
                # Extract if archive
                name_lower = filename.lower()
                if (
                    name_lower.endswith(".zip")
                    or name_lower.endswith(".tar.gz")
                    or name_lower.endswith(".tgz")
                    or name_lower.endswith(".tar")
                ):
                    self._extract_archive(file_path, dest)
            except Exception as exc:
                print(f"[DatasetDownloader] Warning: could not download {file_url}: {exc}")

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

        # Determine task type
        try:
            target_series = df.iloc[:, -1]
            max_unique = target_series.nunique()
            task_type = "classification" if max_unique <= 20 else "regression"
        except Exception:
            task_type = "classification"

        source_url = f"https://www.openml.org/d/{dataset_id}"
        self._write_metadata(dest, df, source_url=source_url, task_type=task_type)
        return dest

    def _download_harvard_dataverse(self, doi: str, dest: Path) -> Path:
        """Download a dataset from Harvard Dataverse.

        Uses the Dataverse REST API to list files, then downloads each one.

        Parameters
        ----------
        doi:
            Persistent identifier (DOI) for the Dataverse dataset.
        dest:
            Destination directory.
        """
        api_url = f"https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId={doi}"
        try:
            response = requests.get(api_url, timeout=30)
            response.raise_for_status()
            data = response.json()
        except requests.RequestException as exc:
            raise RuntimeError(f"Failed to fetch Harvard Dataverse metadata for doi={doi}: {exc}") from exc

        try:
            files = data["data"]["latestVersion"]["files"]
        except (KeyError, TypeError) as exc:
            raise RuntimeError(f"Unexpected Harvard Dataverse API response structure: {exc}") from exc

        dest.mkdir(parents=True, exist_ok=True)

        for file_info in files:
            try:
                file_id = file_info["dataFile"]["id"]
                filename = file_info["dataFile"]["filename"]
                file_url = f"https://dataverse.harvard.edu/api/access/datafile/{file_id}"
                file_path = dest / filename
                r = requests.get(file_url, stream=True, timeout=120)
                r.raise_for_status()
                total = int(r.headers.get("Content-Length", 0)) or None
                with (
                    open(file_path, "wb") as fh,
                    tqdm(
                        desc=filename,
                        total=total,
                        unit="B",
                        unit_scale=True,
                        unit_divisor=1024,
                    ) as pbar,
                ):
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            fh.write(chunk)
                            pbar.update(len(chunk))
            except Exception as exc:
                print(f"[DatasetDownloader] Warning: could not download file from Harvard Dataverse: {exc}")

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
            response = requests.get(api_url, timeout=30)
            response.raise_for_status()
            files = response.json()
        except requests.RequestException as exc:
            raise RuntimeError(f"Failed to fetch FigShare article files for id={article_id}: {exc}") from exc

        if not isinstance(files, list) or not files:
            raise RuntimeError(f"FigShare article {article_id} has no downloadable files.")

        dest.mkdir(parents=True, exist_ok=True)

        for file_info in files:
            try:
                file_url = file_info["download_url"]
                filename = file_info.get("name") or file_url.split("/")[-1]
                file_path = dest / filename
                r = requests.get(file_url, stream=True, timeout=120)
                r.raise_for_status()
                total = int(r.headers.get("Content-Length", 0)) or None
                with (
                    open(file_path, "wb") as fh,
                    tqdm(
                        desc=filename,
                        total=total,
                        unit="B",
                        unit_scale=True,
                        unit_divisor=1024,
                    ) as pbar,
                ):
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            fh.write(chunk)
                            pbar.update(len(chunk))
                # Extract if archive
                name_lower = filename.lower()
                if (
                    name_lower.endswith(".zip")
                    or name_lower.endswith(".tar.gz")
                    or name_lower.endswith(".tgz")
                    or name_lower.endswith(".tar")
                ):
                    self._extract_archive(file_path, dest)
            except Exception as exc:
                print(
                    f"[DatasetDownloader] Warning: could not download FigShare file "
                    f"{file_info.get('name', '?')}: {exc}"
                )

        return dest

    def _extract_archive(self, archive_path: Path, dest: Path) -> Path:
        """Extract a zip or tar archive into ``dest`` and delete the archive.

        Parameters
        ----------
        archive_path:
            Path to the archive file on disk.
        dest:
            Directory into which the archive contents will be extracted.
        """
        name_lower = archive_path.name.lower()
        try:
            if name_lower.endswith(".zip"):
                with zipfile.ZipFile(archive_path, "r") as zf:
                    zf.extractall(dest)
            elif name_lower.endswith(".tar.gz") or name_lower.endswith(".tgz") or name_lower.endswith(".tar"):
                with tarfile.open(archive_path, "r:*") as tf:
                    tf.extractall(dest)
            else:
                print(
                    f"[DatasetDownloader] Warning: unrecognised archive format for "
                    f"{archive_path.name}, leaving as-is."
                )
                return dest
        except Exception as exc:
            print(f"[DatasetDownloader] Warning: could not extract {archive_path.name}: {exc}")
            return dest

        try:
            archive_path.unlink()
        except OSError as exc:
            print(f"[DatasetDownloader] Warning: could not delete archive {archive_path}: {exc}")

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
