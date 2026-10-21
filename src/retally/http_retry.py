"""Retry transient HTTP failures for paper and dataset downloads.

Large downloads (paper PDFs, Zenodo / Dataverse replication-package zips)
occasionally die mid-stream with ``ChunkedEncodingError`` / connection
resets / incomplete reads.  Without a retry the benchmark runner records
the whole paper as an error row and caches it.  This module is the one
place both download paths (``retally.paper.parser`` and
``retally.dataset.downloader``) get their retry policy from.

Policy: up to ``DEFAULT_ATTEMPTS`` (3) attempts, exponential backoff
starting at ``DEFAULT_BASE_DELAY`` (2 s, then 4 s) with up to +50 %
jitter.  Retried: connection errors, chunked-encoding / incomplete-read
errors, timeouts, and HTTP 5xx.  Not retried: HTTP 4xx (a 404 or 403
will not fix itself) and anything else.
"""

from __future__ import annotations

import http.client
import logging
import random
import time
from collections.abc import Callable
from typing import Any, TypeVar

import requests
import urllib3.exceptions

logger = logging.getLogger(__name__)

T = TypeVar("T")

DEFAULT_ATTEMPTS = 3
DEFAULT_BASE_DELAY = 2.0

_TRANSIENT_EXCEPTIONS: tuple[type[BaseException], ...] = (
    requests.exceptions.ConnectionError,  # includes ConnectTimeout, ProxyError, SSLError
    requests.exceptions.ChunkedEncodingError,
    requests.exceptions.Timeout,  # ConnectTimeout + ReadTimeout
    requests.exceptions.ContentDecodingError,
    http.client.IncompleteRead,
    urllib3.exceptions.ProtocolError,
    urllib3.exceptions.ReadTimeoutError,
)


def is_retryable(exc: BaseException) -> bool:
    """True for transient network failures and HTTP 5xx; False for 4xx and the rest."""
    if isinstance(exc, requests.exceptions.HTTPError):
        status = getattr(getattr(exc, "response", None), "status_code", None)
        return status is not None and 500 <= int(status) < 600
    return isinstance(exc, _TRANSIENT_EXCEPTIONS)


def with_retries(
    fn: Callable[[], T],
    *,
    what: str = "HTTP request",
    attempts: int = DEFAULT_ATTEMPTS,
    base_delay: float = DEFAULT_BASE_DELAY,
    sleep: Callable[[float], None] = time.sleep,
) -> T:
    """Call ``fn`` and return its result, retrying transient failures.

    ``fn`` should do the whole fetch, *including* reading the body: a
    chunked-encoding error surfaces while iterating the response, so
    wrapping only ``session.get`` would not catch it.  The last exception
    is re-raised once ``attempts`` are spent; a non-retryable exception is
    re-raised immediately.
    """
    for attempt in range(1, attempts + 1):
        try:
            return fn()
        except Exception as exc:
            if attempt >= attempts or not is_retryable(exc):
                raise
            delay = base_delay * (2 ** (attempt - 1)) * (1 + random.random() * 0.5)
            logger.warning(
                "%s failed (attempt %d/%d: %s: %s); retrying in %.1fs",
                what,
                attempt,
                attempts,
                type(exc).__name__,
                exc,
                delay,
            )
            sleep(delay)
    raise AssertionError("unreachable")  # pragma: no cover


def get_with_retries(
    url: str,
    *,
    session: Any = None,
    attempts: int = DEFAULT_ATTEMPTS,
    base_delay: float = DEFAULT_BASE_DELAY,
    sleep: Callable[[float], None] = time.sleep,
    **kwargs: Any,
) -> requests.Response:
    """``session.get(url, **kwargs)`` + ``raise_for_status()``, with retries.

    ``session`` defaults to the ``requests`` module itself.  Suitable for
    non-streamed responses (metadata JSON, small pages).  For streamed
    downloads wrap the get *and* the body read in :func:`with_retries`.
    """
    http = session if session is not None else requests

    def _get() -> requests.Response:
        response = http.get(url, **kwargs)
        response.raise_for_status()
        return response

    return with_retries(_get, what=f"GET {url}", attempts=attempts, base_delay=base_delay, sleep=sleep)
