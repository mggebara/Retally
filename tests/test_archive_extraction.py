"""DatasetDownloader._extract_archive: nested archives, zip-slip, size cap.

Fixtures are built in ``tmp_path``; no network.
"""

from __future__ import annotations

import io
import tarfile
import zipfile
from pathlib import Path
from unittest.mock import patch

from retally.dataset.downloader import DatasetDownloader


def _zip_bytes(members: dict[str, bytes]) -> bytes:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        for name, data in members.items():
            zf.writestr(name, data)
    return buf.getvalue()


def _tgz_bytes(members: dict[str, bytes]) -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tf:
        for name, data in members.items():
            info = tarfile.TarInfo(name)
            info.size = len(data)
            tf.addfile(info, io.BytesIO(data))
    return buf.getvalue()


def _write(path: Path, data: bytes) -> Path:
    path.write_bytes(data)
    return path


def _extract(tmp_path: Path, archive_name: str, data: bytes) -> Path:
    dest = tmp_path / "pkg"
    dest.mkdir()
    archive = _write(dest / archive_name, data)
    DatasetDownloader(cache_dir=tmp_path)._extract_archive(archive, dest)
    return dest


def test_zip_in_zip_is_extracted_into_a_directory_named_after_it(tmp_path):
    inner = _zip_bytes({"data/main.csv": b"a,b\n", "README.txt": b"hi"})
    outer = _zip_bytes({"replication/inner.zip": inner, "replication/run.R": b"x <- 1"})
    dest = _extract(tmp_path, "outer.zip", outer)

    assert not (dest / "outer.zip").exists()
    assert (dest / "replication" / "run.R").read_bytes() == b"x <- 1"
    assert (dest / "replication" / "inner" / "data" / "main.csv").read_bytes() == b"a,b\n"
    assert (dest / "replication" / "inner" / "README.txt").exists()
    assert not (dest / "replication" / "inner.zip").exists()


def test_tgz_in_zip_is_extracted(tmp_path):
    inner = _tgz_bytes({"Replication/data.dta": b"stata", "Replication/code.do": b"reg y x"})
    outer = _zip_bytes({"package.tgz": inner})
    dest = _extract(tmp_path, "outer.zip", outer)

    assert (dest / "package" / "Replication" / "data.dta").read_bytes() == b"stata"
    assert not (dest / "package.tgz").exists()


def test_tgz_at_top_level_is_extracted(tmp_path):
    dest = _extract(tmp_path, "Replication.tgz", _tgz_bytes({"Replication/x.csv": b"1"}))
    assert (dest / "Replication" / "x.csv").read_bytes() == b"1"
    assert not (dest / "Replication.tgz").exists()


def test_nesting_stops_at_the_depth_cap(tmp_path):
    level3 = _zip_bytes({"deep.csv": b"d"})
    level2 = _zip_bytes({"l3.zip": level3})
    level1 = _zip_bytes({"l2.zip": level2})
    dest = _extract(tmp_path, "l0.zip", _zip_bytes({"l1.zip": level1}))

    # Depth 1 and 2 are extracted; the archive found at depth 2 is left as-is.
    assert (dest / "l1" / "l2" / "l3.zip").is_file()
    assert not (dest / "l1.zip").exists()
    assert not (dest / "l1" / "l2.zip").exists()


def test_macos_resource_fork_stubs_are_not_treated_as_archives(tmp_path):
    outer = _zip_bytes({"__MACOSX/._inner.zip": b"\x00\x05\x16\x07", "._other.zip": b"junk"})
    dest = _extract(tmp_path, "outer.zip", outer)
    assert (dest / "__MACOSX" / "._inner.zip").is_file()
    assert (dest / "._other.zip").is_file()


def test_zip_slip_member_is_refused(tmp_path):
    evil = _zip_bytes({"ok.csv": b"1", "../escaped.txt": b"pwned"})
    dest = _extract(tmp_path, "evil.zip", evil)

    assert not (tmp_path / "escaped.txt").exists()
    assert not (dest / "ok.csv").exists()
    assert (dest / "evil.zip").is_file()  # refused archives stay in place


def test_nested_zip_slip_is_refused(tmp_path):
    inner = _zip_bytes({"../../escaped.txt": b"pwned"})
    dest = _extract(tmp_path, "outer.zip", _zip_bytes({"inner.zip": inner}))

    assert not (tmp_path / "escaped.txt").exists()
    assert (dest / "inner.zip").is_file()
    assert not (dest / "inner").exists()


def test_tar_symlink_escaping_dest_is_refused(tmp_path):
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tf:
        link = tarfile.TarInfo("link")
        link.type = tarfile.SYMTYPE
        link.linkname = "../../outside"
        tf.addfile(link)
    dest = _extract(tmp_path, "evil.tgz", buf.getvalue())

    assert not (dest / "link").exists()
    assert (dest / "evil.tgz").is_file()


def test_size_cap_leaves_an_oversized_nested_archive_in_place(tmp_path):
    inner = _zip_bytes({"big.csv": b"x" * 500})
    outer = _zip_bytes({"small.csv": b"y" * 10, "inner.zip": inner})
    # Room for the top-level members, but not for the inner archive's contents.
    with patch("retally.dataset.downloader._MAX_EXTRACTED_BYTES", len(inner) + 10 + 100):
        dest = _extract(tmp_path, "outer.zip", outer)

    assert (dest / "small.csv").exists()
    assert (dest / "inner.zip").is_file()
    assert not (dest / "inner").exists()
