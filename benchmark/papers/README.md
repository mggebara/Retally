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
#
# No claim's `context`, `location` or `unit` may state the value (or
# standard error) of any pinned claim of the same entry: a context that
# says "1,842 dyads", "98 clusters" or "attenuates from 3.713" hands the
# blind model the target of another claim.  Sample sizes, cluster counts
# and means that are pinned go in `notes`; describe what the number is
# ("the full-sample N", "former-owner clusters"), not its value.
# tests/test_catalog_contexts.py enforces this for every entry.
#
# Printed precision (`decimals`): the comparator never holds a claim to a
# band narrower than half a unit in the last printed place of `value`
# (every mode; see ../README.md, "Printed-precision floor").  The number
# of places is read from how `value` is written here, so copy the value
# exactly as printed, trailing zeros included (`0.0280`, not `0.028`).
# Set `decimals: <int>` on the claim only when the printed precision is
# not what the literal suggests: e.g. a value pinned with more digits
# than the table prints, or a rounded integer (`value: 1100` printed "to
# the nearest hundred" is `decimals: -2`; written integers otherwise
# count as exact).
