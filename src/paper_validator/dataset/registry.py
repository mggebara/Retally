"""
DatasetRegistry — a lookup table mapping common dataset names/identifiers to
their download sources.

The registry is useful for two purposes:
  1. Pre-populating well-known datasets so the pipeline does not need to
     infer download details from scratch.
  2. Caching dataset references that have been resolved automatically (e.g.
     by the ClaimExtractor) so they can be reused across runs.

The backing store is a simple JSON file at ``registry_path``.  Each entry
is serialised as a DatasetReference dict.
"""

from __future__ import annotations

from pathlib import Path

from paper_validator.models import DatasetReference


class DatasetRegistry:
    """Persistent registry of known datasets and their download sources.

    Parameters
    ----------
    registry_path:
        Path to the JSON file used as the backing store.  Created
        automatically if it does not exist.
    """

    def __init__(self, registry_path: Path = Path(".cache/registry.json")) -> None:
        self.registry_path = registry_path
        self._entries: dict[str, DatasetReference] = {}

    def load(self) -> None:
        """Load entries from the JSON file on disk.

        If the file does not exist, initialise with an empty registry.
        Deserialise each entry back into a ``DatasetReference`` dataclass.
        Also call ``_load_builtins()`` to populate well-known datasets.
        """
        raise NotImplementedError

    def save(self) -> None:
        """Persist all entries to the JSON file.

        Serialise each ``DatasetReference`` to a plain dict (use
        ``dataclasses.asdict``).  Write with ``json.dumps(indent=2)``.
        """
        raise NotImplementedError

    def lookup(self, name: str) -> DatasetReference | None:
        """Find a dataset by exact name or by case-insensitive fuzzy match.

        First try an exact key lookup, then try case-insensitive matching,
        then try substring matching.  Return ``None`` if no match is found.
        """
        raise NotImplementedError

    def register(self, reference: DatasetReference) -> None:
        """Add or update a dataset entry in the registry.

        Use ``reference.name`` as the key (lowercase, stripped).
        Call ``save()`` afterwards to persist the change.
        """
        raise NotImplementedError

    def search(self, query: str) -> list[DatasetReference]:
        """Return all datasets whose name or description contains ``query``.

        Case-insensitive substring match on both ``name`` and ``description``.
        """
        raise NotImplementedError

    def _load_builtins(self) -> None:
        """Pre-populate the registry with a curated set of common datasets.

        Add entries for at least:
          - UCI Adult Income   (source=UCI, dataset_id='2')
          - UCI Iris           (source=UCI, dataset_id='53')
          - MNIST              (direct URL to http://yann.lecun.com/exdb/mnist/)
          - Boston Housing     (OpenML id=531)
          - Titanic            (Kaggle slug='heptapod/titanic')
          - California Housing (OpenML id=43939)

        These are registered only if not already present, so user-provided
        overrides are respected.
        """
        raise NotImplementedError
