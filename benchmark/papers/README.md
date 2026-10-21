# This directory holds the per-paper YAML files for the I4R benchmark.
# Empty by design — placeholder fixtures moved to
# tests/fixtures/benchmark_placeholders/ so they don't pollute the
# real catalog.  Add a real entry as `<author>-<year>-<slug>.yaml`
# (see ../README.md and ../schema.py for the schema).
#
# Claim `context` (and `location`) strings are rendered into the code-
# generation prompt in BOTH modes, so they must be writable from the
# published paper alone: no replication-package variable names, file
# names, or Stata/R commands, and no detail the paper does not state.
# Package-only facts a curator needs to keep go in the entry's `notes`
# (not shown to the model).
