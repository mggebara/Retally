"""Shared importlib helpers for loading scripts that live outside ``src/``.

The ``benchmark/`` package and the standalone scripts under ``scripts/``
live at the repo root, not under ``src/retally/``, so the test suite
brings them in via :mod:`importlib` rather than relying on ``sys.path``
gymnastics.  Four test modules used to roll their own
``importlib.util.spec_from_file_location`` boilerplate; this helper
centralises it.

A test module that needs ``benchmark.schema`` writes:

    from tests._loaders import REPO_ROOT, load_module_from_path

    bschema = load_module_from_path(
        "benchmark.schema", REPO_ROOT / "benchmark" / "schema.py"
    )

The helper auto-creates a parent-package stub so dataclasses defined in
the loaded module can find their owner in ``sys.modules`` (a quirk of
``dataclasses.fields`` resolution).
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType

REPO_ROOT = Path(__file__).resolve().parent.parent


def load_module_from_path(name: str, path: Path) -> ModuleType:
    """Load a Python module from ``path`` and register it as ``name``.

    If ``name`` is dotted, intermediate parent packages are created as
    empty module stubs.  Subsequent loads with the same ``name`` return
    the already-loaded module instead of reloading.
    """
    if name in sys.modules:
        return sys.modules[name]

    if "." in name:
        parent_name = name.rsplit(".", 1)[0]
        if parent_name not in sys.modules:
            parent_spec = importlib.util.spec_from_loader(parent_name, loader=None)
            assert parent_spec is not None
            parent = importlib.util.module_from_spec(parent_spec)
            # A package path, so the loaded module's own sibling imports
            # (``from benchmark.strip_rule import ...``) resolve too.
            parent.__path__ = [str(path.parent)]
            sys.modules[parent_name] = parent

    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module
