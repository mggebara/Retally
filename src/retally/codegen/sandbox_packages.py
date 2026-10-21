"""Packages installed in the Retally sandbox images.

The generation and refinement prompts tell the model exactly which
packages it may load: the sandboxes run with ``--network none``, so a
script that loads anything else crashes and burns a refinement round.

These lists mirror the files the images are built from:

* :data:`R_PACKAGES` — ``docker/requirements.sandbox.r.txt`` (in file
  order), followed by :data:`R_BASE_PACKAGES`, the base / recommended
  packages ``docker/check-r-packages.R`` also load-checks.
* :data:`PYTHON_PACKAGES` — the distribution names in
  ``docker/requirements.sandbox.txt`` (in file order).

They are constants rather than a runtime read of those files because
the ``retally`` package is pip-installable without the ``docker/``
directory.  ``tests/test_sandbox_packages.py`` parses both files and
fails if these lists drift from them, so edit the requirements file and
this module together.
"""

from __future__ import annotations

R_INSTALLED_PACKAGES: tuple[str, ...] = (
    "jsonlite",
    "fixest",
    "lfe",
    "AER",
    "ivreg",
    "plm",
    "estimatr",
    "lme4",
    "quantreg",
    "car",
    "sandwich",
    "lmtest",
    "clubSandwich",
    "multiwayvcov",
    "marginaleffects",
    "MatchIt",
    "optmatch",
    "CBPS",
    "WeightIt",
    "cobalt",
    "did",
    "rdrobust",
    "rddensity",
    "Synth",
    "modelsummary",
    "stargazer",
    "texreg",
    "broom",
    "tidyverse",
    "dplyr",
    "tidyr",
    "readr",
    "stringr",
    "lubridate",
    "data.table",
    "haven",
    "readxl",
    "janitor",
    "zoo",
    "ggplot2",
    "ggridges",
    "ggrepel",
    "gridExtra",
    "cowplot",
    "gtable",
    "extrafont",
    "sf",
)
"""Packages listed in ``docker/requirements.sandbox.r.txt``, in file order."""

R_BASE_PACKAGES: tuple[str, ...] = (
    "MASS",
    "nnet",
    "survival",
    "splines",
    "Matrix",
    "boot",
    "stats",
    "utils",
)
"""Base / recommended packages shipped with r-base, load-checked by ``check-r-packages.R``."""

R_PACKAGES: tuple[str, ...] = R_INSTALLED_PACKAGES + R_BASE_PACKAGES
"""Every R package a generated script may load in retally-sandbox-r."""

PYTHON_PACKAGES: tuple[str, ...] = (
    "scikit-learn",
    "xgboost",
    "lightgbm",
    "pandas",
    "numpy",
    "scipy",
    "statsmodels",
    "matplotlib",
)
"""Distributions listed in ``docker/requirements.sandbox.txt``, in file order."""
