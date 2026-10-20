"""Fetch the source of a paper's reference implementation onto local disk.

The current backend is ``git clone --depth 1`` against GitHub URLs.
Other sources in :class:`~retally.models.CodeReferenceSource` are
recorded by the extractor but skipped here — the downloader returns
the unchanged ``CodeReference`` (with ``local_path=None``) so the
caller can see we declined.  Adding GitLab / Zenodo / arbitrary zip
support is a follow-up that slots in next to ``_clone_github``.

Cache layout
------------
Repos land under ``cache_dir / <user>__<repo>``.  A
``.retally-clone-complete`` sentinel file marks a finished clone; a
directory without the sentinel is treated as a stale / partial
checkout and re-cloned (same pattern as the dataset cache).

Safety
------
We only ever READ the cloned files — they're piped into the LLM
prompt, not executed.  The sandbox boundary stays around the generated
reproduction code, which is unchanged by this module.
"""

from __future__ import annotations

import logging
import re
import shutil
import subprocess
from pathlib import Path

from retally.models import CodeReference, CodeReferenceSource

logger = logging.getLogger(__name__)

_COMPLETE_SENTINEL = ".retally-clone-complete"


class CodeDownloader:
    """Clone (or otherwise fetch) reference code linked from a paper.

    Parameters
    ----------
    cache_dir:
        Root directory under which cloned repos live.
    clone_timeout:
        Hard wall-clock cap on ``git clone`` (seconds).  Anything that
        doesn't finish in that window is treated as a failure rather
        than blocking the pipeline indefinitely.
    """

    def __init__(
        self,
        cache_dir: Path = Path(".cache/code_repos"),
        clone_timeout: int = 120,
    ) -> None:
        self.cache_dir = Path(cache_dir)
        self.clone_timeout = clone_timeout

    def download(self, reference: CodeReference) -> CodeReference:
        """Fetch ``reference`` and return a new CodeReference with ``local_path`` set.

        Returns the original reference unchanged (``local_path=None``)
        when the source is not supported, when git is unavailable, or
        when the fetch fails.  Never raises — code-baseline ingestion
        is best-effort; a failure here must not derail the whole
        pipeline.
        """
        if reference.source is not CodeReferenceSource.GITHUB:
            logger.info(
                "Skipping code reference %s: source=%s is not yet supported.",
                reference.url,
                reference.source.value,
            )
            return reference

        dest = self._local_path(reference)
        if (dest / _COMPLETE_SENTINEL).exists():
            return CodeReference(
                url=reference.url,
                source=reference.source,
                description=reference.description,
                local_path=dest,
            )

        if not _git_available():
            logger.warning(
                "Cannot clone %s: 'git' executable not found on PATH.",
                reference.url,
            )
            return reference

        # Remove any stale partial-clone directory before re-trying.
        if dest.exists():
            shutil.rmtree(dest, ignore_errors=True)
        dest.parent.mkdir(parents=True, exist_ok=True)

        try:
            self._clone_github(reference.url, dest)
        except (subprocess.SubprocessError, OSError) as exc:
            logger.warning("Failed to clone %s: %s", reference.url, exc)
            shutil.rmtree(dest, ignore_errors=True)
            return reference

        (dest / _COMPLETE_SENTINEL).touch()
        return CodeReference(
            url=reference.url,
            source=reference.source,
            description=reference.description,
            local_path=dest,
        )

    def download_all(self, references: list[CodeReference]) -> list[CodeReference]:
        """Convenience: fetch every reference in order, returning resolved copies."""
        return [self.download(r) for r in references]

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _local_path(self, reference: CodeReference) -> Path:
        """Return the cache directory for this reference.

        Uses ``<owner>__<repo>`` as the slug when we can parse one out
        of a GitHub URL; falls back to a hash-style filesystem slug of
        the URL otherwise.
        """
        owner, repo = _parse_github_owner_repo(reference.url)
        if owner and repo:
            slug = f"{owner}__{repo}"
        else:
            slug = re.sub(r"[^a-z0-9]+", "_", reference.url.lower()).strip("_")
        return self.cache_dir / slug

    def _clone_github(self, url: str, dest: Path) -> None:
        """Shallow-clone ``url`` into ``dest``.  Raises on failure."""
        cmd = [
            "git",
            "clone",
            "--depth",
            "1",
            "--filter=blob:none",  # skip blobs we don't need (large files etc.)
            url,
            str(dest),
        ]
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=self.clone_timeout,
        )
        if result.returncode != 0:
            raise subprocess.CalledProcessError(
                returncode=result.returncode,
                cmd=cmd,
                output=result.stdout,
                stderr=result.stderr,
            )


# ---------------------------------------------------------------------------
# Module-level helpers
# ---------------------------------------------------------------------------


def _git_available() -> bool:
    """Return True if ``git`` is on the PATH and runnable."""
    try:
        result = subprocess.run(
            ["git", "--version"],
            capture_output=True,
            timeout=5,
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return False


_GITHUB_URL_RE = re.compile(
    r"^https?://(?:www\.)?github\.com/(?P<owner>[A-Za-z0-9_.-]+)/(?P<repo>[A-Za-z0-9_.-]+?)(?:\.git)?/?$"
)


def _parse_github_owner_repo(url: str) -> tuple[str | None, str | None]:
    """Return ``(owner, repo)`` for a GitHub URL or ``(None, None)``.

    Strips trailing slashes, ``.git`` suffix, and ``www.`` host prefix.
    Does NOT validate the repo exists — that's the clone command's job.
    """
    match = _GITHUB_URL_RE.match(url.strip())
    if not match:
        return None, None
    return match.group("owner"), match.group("repo")
