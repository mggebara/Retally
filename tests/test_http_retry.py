"""Tests for the shared download retry helper (retally.http_retry)."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
import requests

from retally import http_retry


def _response(status: int = 200, text: str = "ok") -> MagicMock:
    resp = MagicMock()
    resp.status_code = status
    resp.text = text
    if status >= 400:
        err = requests.exceptions.HTTPError(f"{status} error", response=resp)
        resp.raise_for_status.side_effect = err
    else:
        resp.raise_for_status.return_value = None
    return resp


def test_retries_transient_errors_then_succeeds():
    session = MagicMock()
    ok = _response()
    session.get.side_effect = [
        requests.exceptions.ChunkedEncodingError("Connection broken: IncompleteRead"),
        requests.exceptions.ConnectionError("reset by peer"),
        ok,
    ]
    sleeps: list[float] = []

    result = http_retry.get_with_retries("https://zenodo.org/x.zip", session=session, sleep=sleeps.append)

    assert result is ok
    assert session.get.call_count == 3
    # Exponential backoff from 2 s with up to +50 % jitter: [2, 3) then [4, 6).
    assert len(sleeps) == 2
    assert 2.0 <= sleeps[0] < 3.0
    assert 4.0 <= sleeps[1] < 6.0


def test_404_is_not_retried():
    session = MagicMock()
    session.get.return_value = _response(404)
    sleeps: list[float] = []

    with pytest.raises(requests.exceptions.HTTPError):
        http_retry.get_with_retries("https://example.org/missing", session=session, sleep=sleeps.append)

    assert session.get.call_count == 1
    assert sleeps == []


def test_5xx_is_retried():
    session = MagicMock()
    ok = _response()
    session.get.side_effect = [_response(503), ok]
    assert http_retry.get_with_retries("https://example.org", session=session, sleep=lambda _: None) is ok
    assert session.get.call_count == 2


def test_gives_up_after_three_attempts_and_reraises_last_error():
    session = MagicMock()
    session.get.side_effect = requests.exceptions.Timeout("read timed out")
    with pytest.raises(requests.exceptions.Timeout):
        http_retry.get_with_retries("https://example.org", session=session, sleep=lambda _: None)
    assert session.get.call_count == 3


def test_non_network_errors_are_not_retried():
    calls = []

    def boom():
        calls.append(1)
        raise ValueError("not a network problem")

    with pytest.raises(ValueError):
        http_retry.with_retries(boom, sleep=lambda _: None)
    assert len(calls) == 1


def test_stream_to_file_retries_a_mid_stream_failure(tmp_path):
    """The dataset download retries a body read that dies part-way, and rewrites the file."""
    from retally.dataset.downloader import DatasetDownloader

    def _streaming(chunks_or_error):
        resp = _response()
        resp.headers = {}

        def _iter(chunk_size=8192):
            for c in chunks_or_error:
                if isinstance(c, Exception):
                    raise c
                yield c

        resp.iter_content.side_effect = _iter
        return resp

    broken = _streaming([b"partial", requests.exceptions.ChunkedEncodingError("broken")])
    good = _streaming([b"full ", b"body"])
    with (
        patch("retally.dataset.downloader.requests.get", side_effect=[broken, good]) as get,
        patch("retally.http_retry.time.sleep"),
    ):
        out = DatasetDownloader(cache_dir=tmp_path)._stream_to_file(
            "https://zenodo.org/f.csv", tmp_path, "f.csv"
        )

    assert get.call_count == 2
    assert Path(out).read_bytes() == b"full body"


def test_paper_pdf_download_retries_a_connection_error(tmp_path):
    from retally.paper import parser as parser_mod

    good = _response()
    good.iter_content.return_value = [b"%PDF-1.4 ..."]
    with (
        patch(
            "retally.paper.parser.requests.get",
            side_effect=[requests.exceptions.ConnectionError("dns"), good],
        ) as get,
        patch("retally.http_retry.time.sleep"),
    ):
        path = parser_mod._download_pdf("https://arxiv.org/pdf/0000.00000")

    try:
        assert get.call_count == 2
        assert path.read_bytes() == b"%PDF-1.4 ..."
    finally:
        path.unlink(missing_ok=True)
