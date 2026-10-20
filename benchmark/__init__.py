"""Retally benchmark harness.

Scores a reproducer (by default ``ValidationPipeline``, via the
``Reproducer`` protocol in ``benchmark.reproducer``) against an external
ground-truth catalog (initially: papers replicated by the Institute for
Replication) and produces per-paper + aggregate metrics.  See ``benchmark/README.md``
for the workflow.
"""
