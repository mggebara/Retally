"""Every outbound HTTP request carries Retally's User-Agent.

Harvard Dataverse answers the default ``python-requests/x.y`` agent with
403 Forbidden, so a request that forgets the header breaks dataset
downloads.  No network: ``requests.get`` / ``requests.head`` are mocked.
"""

from __future__ import annotations

import re
from pathlib import Path
from unittest.mock import MagicMock, patch

from retally import http_retry
from retally.http_retry import USER_AGENT, get_with_retries, http_get, http_head

ROOT = Path(__file__).resolve().parents[1]
SCANNED = [ROOT / "src" / "retally", ROOT / "benchmark", ROOT / "scripts"]


def _ok():
    resp = MagicMock()
    resp.raise_for_status.return_value = None
    resp.headers = {}
    return resp


def test_user_agent_names_retally_and_its_version():
    assert USER_AGENT.startswith("Retally/")
    assert "github.com/mggebara/Retally" in USER_AGENT
    assert "python-requests" not in USER_AGENT


def test_http_get_and_head_send_the_user_agent():
    with patch("requests.get", return_value=_ok()) as get, patch("requests.head", return_value=_ok()) as head:
        http_get("https://dataverse.harvard.edu/api/x", timeout=5)
        http_head("https://example.org/f.zip", allow_redirects=True)
    assert get.call_args.kwargs["headers"]["User-Agent"] == USER_AGENT
    assert get.call_args.kwargs["timeout"] == 5
    assert head.call_args.kwargs["headers"]["User-Agent"] == USER_AGENT


def test_caller_headers_are_kept_and_user_agent_added():
    with patch("requests.get", return_value=_ok()) as get:
        get_with_retries("https://doi.org/10.1/x", headers={"Accept": "application/json"})
    headers = get.call_args.kwargs["headers"]
    assert headers == {"Accept": "application/json", "User-Agent": USER_AGENT}


def test_get_with_retries_on_a_custom_session_still_sends_the_user_agent():
    session = MagicMock()
    session.get.return_value = _ok()
    get_with_retries("https://zenodo.org/api/records/1", session=session)
    assert session.get.call_args.kwargs["headers"]["User-Agent"] == USER_AGENT


def test_dataverse_metadata_fetch_sends_the_user_agent(tmp_path):
    from retally.dataset.downloader import DatasetDownloader

    with patch("requests.get", side_effect=RuntimeError("stop after the request")) as get:
        try:
            DatasetDownloader(cache_dir=tmp_path)._download_harvard_dataverse("10.7910/DVN/S5YMS7", tmp_path)
        except RuntimeError:
            pass
    assert get.called
    assert get.call_args.kwargs["headers"]["User-Agent"] == USER_AGENT


def test_paper_pdf_download_sends_the_user_agent():
    from retally.paper import parser as parser_mod

    resp = _ok()
    resp.iter_content.return_value = [b"%PDF-1.4"]
    with patch("requests.get", return_value=resp) as get:
        path = parser_mod._download_pdf("https://arxiv.org/pdf/0000.00000")
    path.unlink(missing_ok=True)
    assert get.call_args.kwargs["headers"]["User-Agent"] == USER_AGENT


def test_no_direct_requests_calls_outside_http_retry():
    """New call sites must go through ``retally.http_retry`` so they get the header."""
    pattern = re.compile(r"\brequests\.(get|head|post|put|request|Session)\(|urllib\.request|urlopen\(")
    offenders = [
        f"{p.relative_to(ROOT)}:{i}"
        for d in SCANNED
        for p in d.rglob("*.py")
        if p.resolve() != Path(http_retry.__file__).resolve() and ".cache" not in p.parts
        for i, line in enumerate(p.read_text().splitlines(), 1)
        if pattern.search(line)
    ]
    assert offenders == []
