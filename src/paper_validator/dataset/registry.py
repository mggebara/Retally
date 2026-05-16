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

import json
from dataclasses import asdict
from pathlib import Path

from paper_validator.models import DatasetReference, DatasetSource


class DatasetRegistry:
    """Persistent registry of known datasets and their download sources.

    Parameters
    ----------
    registry_path:
        Path to the JSON file used as the backing store.  Created
        automatically if it does not exist.
    """

    def __init__(self, registry_path: Path = Path(".cache/registry.json")) -> None:
        self.registry_path = Path(registry_path)
        self._entries: dict[str, DatasetReference] = {}

    def load(self) -> None:
        """Load entries from the JSON file on disk.

        If the file does not exist, initialise with an empty registry.
        Deserialise each entry back into a ``DatasetReference`` dataclass.
        Also call ``_load_builtins()`` to populate well-known datasets.
        """
        self._entries = {}
        if self.registry_path.exists():
            try:
                with open(self.registry_path, "r", encoding="utf-8") as fh:
                    raw = json.load(fh)
                for key, entry in raw.items():
                    source_val = entry.get("source", DatasetSource.UNKNOWN.value)
                    try:
                        source = DatasetSource(source_val)
                    except ValueError:
                        source = DatasetSource.UNKNOWN
                    self._entries[key] = DatasetReference(
                        name=entry.get("name", key),
                        source=source,
                        url=entry.get("url"),
                        description=entry.get("description", ""),
                        access_instructions=entry.get("access_instructions"),
                    )
            except (json.JSONDecodeError, KeyError, TypeError) as exc:
                print(f"[DatasetRegistry] Warning: could not parse registry file: {exc}")
                self._entries = {}

        self._load_builtins()

    def save(self) -> None:
        """Persist all entries to the JSON file.

        Serialise each ``DatasetReference`` to a plain dict (use
        ``dataclasses.asdict``).  Write with ``json.dumps(indent=2)``.
        """
        self.registry_path.parent.mkdir(parents=True, exist_ok=True)
        serialisable: dict[str, dict] = {}
        for key, ref in self._entries.items():
            d = asdict(ref)
            # Convert DatasetSource enum to its string value
            d["source"] = ref.source.value
            serialisable[key] = d
        with open(self.registry_path, "w", encoding="utf-8") as fh:
            json.dump(serialisable, fh, indent=2)

    def lookup(self, name: str) -> DatasetReference | None:
        """Find a dataset by exact name or by case-insensitive fuzzy match.

        First try an exact key lookup, then try case-insensitive matching,
        then try substring matching.  Return ``None`` if no match is found.
        """
        normalised = name.lower().strip()

        # 1. Exact match on normalised key
        if normalised in self._entries:
            return self._entries[normalised]

        # 2. Case-insensitive substring: key contains query or query contains key
        for key, ref in self._entries.items():
            if key == normalised:
                return ref

        # 3. Case-insensitive substring match
        for key, ref in self._entries.items():
            if normalised in key or key in normalised:
                return ref

        return None

    def register(self, reference: DatasetReference) -> None:
        """Add or update a dataset entry in the registry.

        Use ``reference.name`` as the key (lowercase, stripped).
        Call ``save()`` afterwards to persist the change.
        """
        key = reference.name.lower().strip()
        self._entries[key] = reference
        self.save()

    def search(self, query: str) -> list[DatasetReference]:
        """Return all datasets whose name or description contains ``query``.

        Case-insensitive substring match on both ``name`` and ``description``.
        """
        q = query.lower()
        results = []
        for ref in self._entries.values():
            if q in ref.name.lower() or q in ref.description.lower():
                results.append(ref)
        return results

    def _load_builtins(self) -> None:
        """Pre-populate the registry with a curated set of common datasets.

        Entries are registered only if not already present, so user-provided
        overrides are respected.
        """
        builtins: list[DatasetReference] = [
            # --- UCI datasets ---
            DatasetReference(
                name="Iris",
                source=DatasetSource.UCI,
                url="53",
                description="Classic multiclass flower classification dataset.",
            ),
            DatasetReference(
                name="Adult Income",
                source=DatasetSource.UCI,
                url="2",
                description="Census income binary classification",
            ),
            DatasetReference(
                name="Breast Cancer Wisconsin",
                source=DatasetSource.UCI,
                url="17",
                description="Binary classification of breast cancer tumours.",
            ),
            DatasetReference(
                name="Wine",
                source=DatasetSource.UCI,
                url="109",
                description="Wine cultivar multiclass classification.",
            ),
            DatasetReference(
                name="Heart Disease",
                source=DatasetSource.UCI,
                url="45",
                description="Binary classification for presence of heart disease.",
            ),
            DatasetReference(
                name="Ionosphere",
                source=DatasetSource.UCI,
                url="52",
                description="Binary classification of radar returns from the ionosphere.",
            ),
            DatasetReference(
                name="Sonar",
                source=DatasetSource.UCI,
                url="151",
                description="Sonar signal classification (mines vs rocks).",
            ),
            DatasetReference(
                name="Pima Indians Diabetes",
                source=DatasetSource.UCI,
                url="34",
                description="Binary diabetes classification for Pima Indian women.",
            ),
            DatasetReference(
                name="German Credit",
                source=DatasetSource.UCI,
                url="144",
                description="Credit risk binary classification.",
            ),
            DatasetReference(
                name="Letter Recognition",
                source=DatasetSource.UCI,
                url="59",
                description="Multiclass recognition of capital letter images.",
            ),
            DatasetReference(
                name="Mushroom",
                source=DatasetSource.UCI,
                url="73",
                description="Binary edible/poisonous mushroom classification.",
            ),
            DatasetReference(
                name="Soybean Large",
                source=DatasetSource.UCI,
                url="90",
                description="Multiclass soybean disease classification.",
            ),
            DatasetReference(
                name="Zoo",
                source=DatasetSource.UCI,
                url="111",
                description="Multiclass animal classification.",
            ),
            DatasetReference(
                name="Car Evaluation",
                source=DatasetSource.UCI,
                url="19",
                description="Multiclass car acceptability evaluation.",
            ),
            DatasetReference(
                name="Congressional Voting Records",
                source=DatasetSource.UCI,
                url="105",
                description="Binary party classification from US House votes.",
            ),
            DatasetReference(
                name="Abalone",
                source=DatasetSource.UCI,
                url="1",
                description="Abalone age prediction (regression/classification).",
            ),
            DatasetReference(
                name="Statlog Shuttle",
                source=DatasetSource.UCI,
                url="148",
                description="Multiclass shuttle dataset from NASA.",
            ),
            DatasetReference(
                name="Ecoli",
                source=DatasetSource.UCI,
                url="39",
                description="Multiclass E. coli protein localisation site.",
            ),
            DatasetReference(
                name="Yeast",
                source=DatasetSource.UCI,
                url="110",
                description="Multiclass yeast protein localisation.",
            ),
            DatasetReference(
                name="Glass Identification",
                source=DatasetSource.UCI,
                url="42",
                description="Multiclass glass type identification.",
            ),
            DatasetReference(
                name="Balance Scale",
                source=DatasetSource.UCI,
                url="12",
                description="Multiclass balance scale tip prediction.",
            ),
            DatasetReference(
                name="Tic-Tac-Toe Endgame",
                source=DatasetSource.UCI,
                url="101",
                description="Binary classification of tic-tac-toe board outcomes.",
            ),
            DatasetReference(
                name="Spambase",
                source=DatasetSource.UCI,
                url="94",
                description="Binary spam e-mail classification.",
            ),
            DatasetReference(
                name="Waveform",
                source=DatasetSource.UCI,
                url="107",
                description="Multiclass waveform type classification.",
            ),
            # --- OpenML datasets ---
            DatasetReference(
                name="Boston Housing",
                source=DatasetSource.OPENML,
                url="531",
                description="Classic regression dataset predicting Boston house prices.",
            ),
            DatasetReference(
                name="California Housing",
                source=DatasetSource.OPENML,
                url="43939",
                description="California census housing price regression dataset.",
            ),
            DatasetReference(
                name="MNIST",
                source=DatasetSource.OPENML,
                url="554",
                description="Handwritten digit recognition dataset (70 000 samples, 10 classes).",
            ),
            # --- Kaggle datasets ---
            DatasetReference(
                name="Titanic",
                source=DatasetSource.KAGGLE,
                url="heptapod/titanic",
                description="Binary survival classification for Titanic passengers.",
                access_instructions=(
                    "Requires a Kaggle account and ~/.kaggle/kaggle.json credentials."
                ),
            ),
        ]

        for ref in builtins:
            key = ref.name.lower().strip()
            if key not in self._entries:
                self._entries[key] = ref
