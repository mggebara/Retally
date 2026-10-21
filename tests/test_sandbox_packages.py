"""Drift guard: the prompt's package lists match the sandbox images' own lists.

``retally.codegen.sandbox_packages`` holds the R and Python package lists
as constants (the package is pip-installable without ``docker/``).  These
tests parse the files the images are actually built from and fail if the
constants disagree, so adding a package to an image without telling the
prompt (or vice versa) is caught.
"""

from __future__ import annotations

import re
from pathlib import Path

from retally.codegen.sandbox_packages import (
    PYTHON_PACKAGES,
    R_BASE_PACKAGES,
    R_INSTALLED_PACKAGES,
    R_PACKAGES,
)

DOCKER_DIR = Path(__file__).resolve().parent.parent / "docker"


def _requirement_lines(path: Path) -> list[str]:
    """Non-empty lines of a requirements file with ``#`` comments stripped."""
    lines = (re.sub(r"#.*$", "", line).strip() for line in path.read_text().splitlines())
    return [line for line in lines if line]


def test_r_packages_match_requirements_file() -> None:
    listed = _requirement_lines(DOCKER_DIR / "requirements.sandbox.r.txt")
    # install2.r gets the whitespace-split tokens; one name per line is the format.
    assert all(len(line.split()) == 1 for line in listed)
    assert list(R_INSTALLED_PACKAGES) == listed


def test_r_base_packages_match_check_script() -> None:
    script = (DOCKER_DIR / "check-r-packages.R").read_text()
    match = re.search(r"base_pkgs\s*<-\s*c\(([^)]*)\)", script)
    assert match, "base_pkgs <- c(...) not found in check-r-packages.R"
    base = re.findall(r'"([^"]+)"', match.group(1))
    assert list(R_BASE_PACKAGES) == base


def test_r_packages_is_installed_plus_base_without_duplicates() -> None:
    assert R_PACKAGES == R_INSTALLED_PACKAGES + R_BASE_PACKAGES
    assert len(set(R_PACKAGES)) == len(R_PACKAGES)


def test_python_packages_match_requirements_file() -> None:
    listed = _requirement_lines(DOCKER_DIR / "requirements.sandbox.txt")
    names = [re.split(r"[\s<>=!~;\[]", line, maxsplit=1)[0] for line in listed]
    assert list(PYTHON_PACKAGES) == names
