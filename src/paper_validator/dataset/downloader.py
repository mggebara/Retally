"""
DatasetDownloader — retrieves datasets from various public repositories and
stores them locally.

Each public source has its own download strategy.  The main ``download``
method dispatches to the appropriate private helper based on
``DatasetReference.source``.

Supported sources (to be implemented):
  - Direct URL          (HTTP/HTTPS, with redirect handling)
  - Kaggle              (requires ~/.kaggle/kaggle.json credentials)
  - Zenodo              (REST API, no auth needed for public datasets)
  - UCI ML Repository   (direct HTTP download from archive.ics.uci.edu)
  - Harvard Dataverse   (REST API)
  - FigShare            (REST API)
  - OpenML              (openml Python package)
"""

from __future__ import annotations

from pathlib import Path

from paper_validator.models import Dataset, DatasetReference, DatasetSource


class DatasetDownloader:
    """Downloads datasets from public repositories to a local directory.

    Parameters
    ----------
    cache_dir:
        Root directory under which datasets are stored.  Each dataset gets
        its own subdirectory named after a slug of the dataset name.
    """

    def __init__(self, cache_dir: Path = Path(".cache/datasets")) -> None:
        self.cache_dir = cache_dir

    def download(self, reference: DatasetReference) -> Dataset:
        """Download the dataset described by ``reference`` and return a Dataset.

        Dispatches to the appropriate private method based on
        ``reference.source``.  If the dataset is already present in the
        cache (check ``_local_path(reference).exists()``), skip the download
        and return the cached Dataset immediately.

        Raises
        ------
        ValueError
            If ``reference.source`` is ``DatasetSource.UNKNOWN`` and no
            ``reference.url`` is provided.
        RuntimeError
            If the download fails after retries.
        """
        raise NotImplementedError

    def _local_path(self, reference: DatasetReference) -> Path:
        """Return the local cache directory for this reference.

        Use a filesystem-safe slug of ``reference.name`` as the directory name
        (lowercase, spaces and slashes replaced with underscores).
        """
        raise NotImplementedError

    def _download_direct_url(self, url: str, dest: Path) -> Path:
        """Download a file from a direct HTTP/HTTPS URL.

        Use ``requests.get`` with ``stream=True`` and write in chunks.
        Show a tqdm progress bar.  Handle redirects automatically
        (requests does this by default).

        Detect whether the response is a zip/tar archive and extract it
        into ``dest`` if so.

        Returns the path to the downloaded (and extracted, if applicable) file.
        """
        raise NotImplementedError

    def _download_kaggle(self, slug: str, dest: Path) -> Path:
        """Download a Kaggle dataset by its slug (e.g. 'username/dataset-name').

        Use the ``kaggle`` CLI package:
          ``kaggle.api.dataset_download_files(slug, path=dest, unzip=True)``

        Raises ``RuntimeError`` with a helpful message if kaggle credentials
        are not configured (``~/.kaggle/kaggle.json`` missing).
        """
        raise NotImplementedError

    def _download_zenodo(self, record_id_or_doi: str, dest: Path) -> Path:
        """Download all files from a Zenodo record.

        Use the Zenodo REST API:
          ``GET https://zenodo.org/api/records/<record_id>``
        to list files, then download each one.  Strip the DOI prefix
        ``10.5281/zenodo.`` to get the numeric record ID if a DOI is supplied.
        """
        raise NotImplementedError

    def _download_uci(self, dataset_id: str, dest: Path) -> Path:
        """Download a dataset from the UCI ML Repository.

        Use the ucimlrepo package if available, or fall back to direct
        HTTP from ``https://archive.ics.uci.edu/static/public/<id>/``.
        """
        raise NotImplementedError

    def _download_harvard_dataverse(self, doi: str, dest: Path) -> Path:
        """Download a dataset from Harvard Dataverse.

        Use the Dataverse API:
          ``GET https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=<doi>``
        to list files, then download each one.
        """
        raise NotImplementedError

    def _download_figshare(self, article_id: str, dest: Path) -> Path:
        """Download files from a FigShare article.

        Use the FigShare public API:
          ``GET https://api.figshare.com/v2/articles/<article_id>/files``
        to list files, then download each one.
        """
        raise NotImplementedError

    def _download_openml(self, dataset_id: int, dest: Path) -> Path:
        """Download a dataset from OpenML.

        Use ``import openml; ds = openml.datasets.get_dataset(dataset_id)``
        and save the resulting dataframe to a CSV in ``dest``.
        """
        raise NotImplementedError

    def _extract_archive(self, archive_path: Path, dest: Path) -> Path:
        """Extract a zip or tar archive into ``dest`` and return ``dest``."""
        raise NotImplementedError
